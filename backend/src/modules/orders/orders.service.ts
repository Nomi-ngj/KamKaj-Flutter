import { BadRequestException, Injectable } from '@nestjs/common';
import { and, asc, desc, eq, gte, inArray, lt, or, sql } from 'drizzle-orm';
import { isOpenNow, orNotFound, to12h } from '../../common/util';
import { env } from '../../config/env';
import { Database, InjectDb } from '../../db/db.module';
import { distanceKm } from '../../db/geo';
import { addresses, orderEvents, orderItems, orders, paymentMethods, products, stores } from '../../db/schema';
import { SettingsService } from '../settings/settings.service';
import { orderJson } from './orders.serializer';

export interface PlaceOrderInput {
  storeId: string;
  addressId: string;
  paymentMethodId: string;
  items: { productId: string; quantity: number; note?: string }[];
}

/** Cancelled orders stay under "current" for this long so the customer sees what happened. */
const RECENT_CANCEL_DAYS = 7;

/** Staging test card: always declined, so the order waits for payment. */
export const DECLINED_TEST_CARD_LAST4 = '0002';

@Injectable()
export class OrdersService {
  constructor(
    @InjectDb() private readonly db: Database,
    private readonly settings: SettingsService,
  ) {}

  async list(userId: string, scope: 'current' | 'past') {
    const recent = new Date(Date.now() - RECENT_CANCEL_DAYS * 24 * 60 * 60 * 1000);
    const where =
      scope === 'current'
        ? or(
            inArray(orders.status, ['awaitingPayment', 'pending', 'inTransit']),
            and(eq(orders.status, 'cancelled'), gte(orders.updatedAt, recent)),
          )
        : or(eq(orders.status, 'delivered'), and(eq(orders.status, 'cancelled'), lt(orders.updatedAt, recent)));

    const rows = await this.db
      .select({ order: orders, storeName: stores.name })
      .from(orders)
      .innerJoin(stores, eq(stores.id, orders.storeId))
      .where(and(eq(orders.userId, userId), where))
      .orderBy(desc(orders.createdAt))
      .limit(100);
    return rows.map((r) => orderJson(r.order, { storeName: r.storeName }));
  }

  async detail(userId: string, orderId: string) {
    const order = await this.own(userId, orderId);
    return this.toJson(order.id);
  }

  async place(userId: string, input: PlaceOrderInput, actor = 'customer') {
    if (!input.items?.length) throw new BadRequestException('Your cart is empty.');

    const [store] = await this.db.select().from(stores).where(eq(stores.id, input.storeId)).limit(1);
    if (!store || !store.isActive) throw new BadRequestException('This store is not available right now.');
    if (!isOpenNow(store.opensAt, store.closesAt)) {
      throw new BadRequestException(`${store.name} is closed right now. It opens at ${to12h(store.opensAt)}.`);
    }

    const [address] = await this.db
      .select()
      .from(addresses)
      .where(and(eq(addresses.id, input.addressId), eq(addresses.userId, userId), eq(addresses.isDeleted, false)))
      .limit(1);
    if (!address) throw new BadRequestException('Choose a delivery address.');

    let distance: number | null = null;
    if (address.latitude != null && address.longitude != null) {
      distance = distanceKm(
        { lat: store.latitude, lng: store.longitude },
        { lat: address.latitude, lng: address.longitude },
      );
      if (distance > store.deliveryRadiusKm) {
        throw new BadRequestException(`${store.name} does not deliver to this address. Choose a closer store.`);
      }
    }

    const [payment] = await this.db
      .select()
      .from(paymentMethods)
      .where(
        and(
          eq(paymentMethods.id, input.paymentMethodId),
          eq(paymentMethods.userId, userId),
          eq(paymentMethods.isDeleted, false),
        ),
      )
      .limit(1);
    if (!payment) throw new BadRequestException('Choose a payment method.');

    const ids = [...new Set(input.items.map((i) => i.productId))];
    const productRows = await this.db
      .select()
      .from(products)
      .where(and(inArray(products.id, ids), eq(products.storeId, store.id)));
    const byId = new Map(productRows.map((p) => [p.id, p]));

    const lines = input.items.map((item) => {
      const product = byId.get(item.productId);
      if (!product) throw new BadRequestException('Some items in your cart are no longer sold by this store.');
      if (!product.isAvailable) throw new BadRequestException(`${product.name} is out of stock. Remove it to continue.`);
      const quantity = Math.trunc(item.quantity);
      if (quantity < 1 || quantity > 50) throw new BadRequestException('Choose a quantity between 1 and 50.');
      return {
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity,
        note: item.note?.trim() || null,
        lineTotal: product.price * quantity,
      };
    });

    const settings = await this.settings.get();
    const subtotal = lines.reduce((sum, l) => sum + l.lineTotal, 0);
    const deliveryFee = subtotal >= settings.freeDeliveryThreshold ? 0 : store.deliveryFee;
    const serviceFee = settings.serviceFee;
    const total = subtotal + deliveryFee + serviceFee;

    const declined = !env().isProduction && payment.type === 'card' && payment.last4 === DECLINED_TEST_CARD_LAST4;
    const status = declined ? 'awaitingPayment' : 'pending';
    const etaMinutes = Number(store.deliveryTime.match(/(\d+)\s*min/)?.[1] ?? 30);
    const toText = [address.apartment, address.street, address.city].filter(Boolean).join(', ');

    const orderId = await this.db.transaction(async (tx) => {
      const [order] = await tx
        .insert(orders)
        .values({
          userId,
          storeId: store.id,
          addressId: address.id,
          paymentMethodId: payment.id,
          status,
          fromText: `${store.name}, ${store.address}`,
          toText,
          distanceKm: distance,
          subtotal,
          deliveryFee,
          serviceFee,
          total,
          statusNote: declined ? 'Your card was declined. Tap Pay to try again.' : null,
          estimatedAt: new Date(Date.now() + etaMinutes * 60_000),
          paidAt: declined || payment.type === 'cash' ? null : new Date(),
        })
        .returning();
      await tx.insert(orderItems).values(lines.map((l) => ({ ...l, orderId: order.id })));
      await tx.insert(orderEvents).values({
        orderId: order.id,
        status,
        actor,
        note: declined ? 'Card declined (staging test card)' : 'Order placed',
      });
      return order.id;
    });
    return this.toJson(orderId);
  }

  /** Placeholder until a payment provider is chosen: marks the order as paid. */
  async pay(userId: string, orderId: string) {
    const order = await this.own(userId, orderId);
    if (order.status !== 'awaitingPayment') throw new BadRequestException('This order does not need payment.');
    await this.db.transaction(async (tx) => {
      await tx
        .update(orders)
        .set({ status: 'pending', paidAt: new Date(), statusNote: 'Payment received • Preparing dispatch' })
        .where(eq(orders.id, order.id));
      await tx.insert(orderEvents).values({ orderId: order.id, status: 'pending', actor: 'customer', note: 'Paid' });
    });
    return this.toJson(order.id);
  }

  /** Places the same items again at today's prices. */
  async reorder(userId: string, orderId: string) {
    const order = await this.own(userId, orderId);
    const items = await this.db.select().from(orderItems).where(eq(orderItems.orderId, order.id));
    const available = items.filter((i) => i.productId);
    if (!available.length) throw new BadRequestException('The items from this order are no longer available.');

    const addressId = order.addressId ?? (await this.defaultId(addresses, userId));
    const paymentMethodId = order.paymentMethodId ?? (await this.defaultId(paymentMethods, userId));
    if (!addressId) throw new BadRequestException('Add a delivery address to re-order.');
    if (!paymentMethodId) throw new BadRequestException('Add a payment method to re-order.');

    return this.place(userId, {
      storeId: order.storeId,
      addressId,
      paymentMethodId,
      items: available.map((i) => ({ productId: i.productId!, quantity: i.quantity, note: i.note ?? undefined })),
    });
  }

  async cancel(userId: string, orderId: string, reason?: string) {
    const order = await this.own(userId, orderId);
    if (!['awaitingPayment', 'pending'].includes(order.status)) {
      throw new BadRequestException('This order can no longer be cancelled.');
    }
    const note = reason?.trim() || 'Cancelled by customer request';
    await this.db.transaction(async (tx) => {
      await tx
        .update(orders)
        .set({ status: 'cancelled', cancelReason: note, cancelledAt: new Date(), statusNote: null })
        .where(eq(orders.id, order.id));
      await tx.insert(orderEvents).values({ orderId: order.id, status: 'cancelled', actor: 'customer', note });
    });
    return this.toJson(order.id);
  }

  async toJson(orderId: string) {
    const [row] = await this.db
      .select({ order: orders, storeName: stores.name })
      .from(orders)
      .innerJoin(stores, eq(stores.id, orders.storeId))
      .where(eq(orders.id, orderId))
      .limit(1);
    const items = await this.db.select().from(orderItems).where(eq(orderItems.orderId, orderId)).orderBy(asc(orderItems.id));
    return orderJson(row.order, { storeName: row.storeName, items });
  }

  private async own(userId: string, orderId: string) {
    const [order] = await this.db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)))
      .limit(1);
    return orNotFound(order, 'order');
  }

  private async defaultId(table: typeof addresses | typeof paymentMethods, userId: string) {
    const [row] = await this.db
      .select({ id: table.id })
      .from(table)
      .where(and(eq(table.userId, userId), eq(table.isDeleted, false)))
      .orderBy(desc(table.isDefault), sql`created_at`)
      .limit(1);
    return row?.id;
  }
}
