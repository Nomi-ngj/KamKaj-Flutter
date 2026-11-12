import { orderItems, orders, OrderStatus } from '../../db/schema';

type OrderRow = typeof orders.$inferSelect;
type ItemRow = typeof orderItems.$inferSelect;

const TITLES: Record<OrderStatus, string> = {
  awaitingPayment: 'Payment required',
  pending: 'Order confirmed',
  inTransit: 'Shipment on the way',
  delivered: 'Delivered',
  cancelled: 'Cancelled',
};

function subtitle(o: OrderRow, storeName?: string): string | null {
  if (o.statusNote) return o.statusNote;
  switch (o.status) {
    case 'awaitingPayment':
      return 'Complete payment to confirm your order';
    case 'pending':
      return storeName ? `Finding a rider near ${storeName}` : 'Preparing your order';
    case 'inTransit':
      return 'Driver assigned • On schedule';
    default:
      return null;
  }
}

/** Matches `OrderMapper.fromJson` in the app, plus details the app can show later. */
export function orderJson(o: OrderRow, opts: { storeName?: string; items?: ItemRow[] } = {}) {
  return {
    id: o.id,
    number: String(o.number),
    title: TITLES[o.status],
    status: o.status,
    from: o.fromText,
    to: o.toText,
    deliveryDate: (o.deliveredAt ?? o.estimatedAt ?? o.createdAt).toISOString(),
    subtitle: subtitle(o, opts.storeName),
    amountDue: o.status === 'awaitingPayment' ? o.total : null,
    courierInfo: o.courierInfo,
    cancelReason: o.cancelReason,
    total: o.total,
    storeId: o.storeId,
    storeName: opts.storeName ?? null,
    subtotal: o.subtotal,
    deliveryFee: o.deliveryFee,
    serviceFee: o.serviceFee,
    distanceKm: o.distanceKm == null ? null : Math.round(o.distanceKm * 10) / 10,
    createdAt: o.createdAt.toISOString(),
    items: opts.items?.map((i) => ({
      productId: i.productId,
      name: i.productName,
      unitPrice: i.unitPrice,
      quantity: i.quantity,
      note: i.note,
      lineTotal: i.lineTotal,
    })),
  };
}
