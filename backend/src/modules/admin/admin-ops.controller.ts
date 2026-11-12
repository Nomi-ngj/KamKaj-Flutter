import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  Patch,
  Post,
  Put,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { and, asc, count, desc, eq, gte, ilike, inArray, isNull, ne, or, SQL, sql, sum } from 'drizzle-orm';
import { mkdirSync } from 'node:fs';
import { extname } from 'node:path';
import { randomBytes } from 'node:crypto';
import { diskStorage } from 'multer';
import { AuthUser, CurrentUser, Public, Roles } from '../../common/auth';
import { orNotFound, pageParams } from '../../common/util';
import { env } from '../../config/env';
import { Database, InjectDb } from '../../db/db.module';
import {
  addresses,
  orderEvents,
  orderItems,
  orders,
  OrderStatus,
  paymentMethods,
  refreshTokens,
  rides,
  services,
  stores,
  users,
  vehicleTypes,
} from '../../db/schema';
import { SignInDto } from '../auth/auth.dto';
import { AuthService, toUserJson } from '../auth/auth.service';
import { SettingsService } from '../settings/settings.service';
import {
  AddPaymentMethodDto,
  ServiceDto,
  SettingsDto,
  UpdateOrderStatusDto,
  UpdateRideDto,
  UpdateServiceDto,
  UpdateUserDto,
  UpdateVehicleTypeDto,
  VehicleTypeDto,
} from './admin.dto';

/** Which status changes the admin panel may make. */
const TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  awaitingPayment: ['pending', 'cancelled'],
  pending: ['inTransit', 'delivered', 'cancelled'],
  inTransit: ['delivered', 'cancelled'],
  delivered: [],
  cancelled: [],
};

/** Start of today in Pakistan time (UTC+5, no daylight saving). */
function startOfTodayPk(): Date {
  const offset = 5 * 60 * 60 * 1000;
  const local = new Date(Date.now() + offset);
  return new Date(Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()) - offset);
}

const isUniqueViolation = (e: unknown) => {
  const err = e as { code?: string; cause?: { code?: string } };
  return err?.code === '23505' || err?.cause?.code === '23505';
};

@ApiTags('Admin')
@ApiBearerAuth()
@Roles('admin', 'staff')
@Controller('admin')
export class AdminOpsController {
  constructor(
    @InjectDb() private readonly db: Database,
    private readonly auth: AuthService,
    private readonly settings: SettingsService,
  ) {}

  // ───────── Auth ─────────

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('auth/sign-in')
  @HttpCode(200)
  async signIn(@Body() dto: SignInDto, @Headers('user-agent') ua?: string) {
    const session = await this.auth.signIn(dto.email, dto.password, ua, ['admin', 'staff']);
    const [user] = await this.db.select({ role: users.role }).from(users).where(eq(users.id, session.user.id));
    return { ...session, user: { ...session.user, role: user.role } };
  }

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return { ...user, appEnv: env().appEnv };
  }

  // ───────── Dashboard ─────────

  @Get('dashboard')
  async dashboard() {
    const today = startOfTodayPk();
    const twoWeeksAgo = new Date(today.getTime() - 13 * 24 * 60 * 60 * 1000);
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const notCancelled = ne(orders.status, 'cancelled');

    const [[todayStats], byStatus, [userStats], [storeStats], daily, topStores, recent] = await Promise.all([
      this.db
        .select({ orders: count(), revenue: sum(orders.total) })
        .from(orders)
        .where(and(gte(orders.createdAt, today), notCancelled)),
      this.db.select({ status: orders.status, n: count() }).from(orders).groupBy(orders.status),
      this.db
        .select({
          total: count(),
          newThisWeek: sql<number>`count(*) filter (where ${users.createdAt} >= ${weekAgo})`,
        })
        .from(users)
        .where(eq(users.role, 'customer')),
      this.db
        .select({ total: count(), active: sql<number>`count(*) filter (where ${stores.isActive})` })
        .from(stores),
      this.db
        .select({
          day: sql<string>`to_char(${orders.createdAt} at time zone 'Asia/Karachi', 'YYYY-MM-DD')`,
          orders: count(),
          revenue: sum(orders.total),
        })
        .from(orders)
        .where(and(gte(orders.createdAt, twoWeeksAgo), notCancelled))
        .groupBy(sql`1`)
        .orderBy(sql`1`),
      this.db
        .select({ storeId: stores.id, name: stores.name, orders: count(), revenue: sum(orders.total) })
        .from(orders)
        .innerJoin(stores, eq(stores.id, orders.storeId))
        .where(and(gte(orders.createdAt, new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)), notCancelled))
        .groupBy(stores.id)
        .orderBy(desc(count()))
        .limit(5),
      this.orderRows(undefined, 8, 0),
    ]);

    const statusCounts = Object.fromEntries(byStatus.map((s) => [s.status, Number(s.n)]));
    // Fill missing days so the chart has 14 bars.
    const series = Array.from({ length: 14 }, (_, i) => {
      const d = new Date(twoWeeksAgo.getTime() + i * 24 * 60 * 60 * 1000 + 5 * 60 * 60 * 1000);
      const key = d.toISOString().slice(0, 10);
      const found = daily.find((x) => x.day === key);
      return { day: key, orders: Number(found?.orders ?? 0), revenue: Number(found?.revenue ?? 0) };
    });

    return {
      today: { orders: Number(todayStats.orders), revenue: Number(todayStats.revenue ?? 0) },
      activeOrders: (statusCounts.pending ?? 0) + (statusCounts.inTransit ?? 0) + (statusCounts.awaitingPayment ?? 0),
      statusCounts,
      customers: { total: Number(userStats.total), newThisWeek: Number(userStats.newThisWeek) },
      stores: { total: Number(storeStats.total), active: Number(storeStats.active) },
      series,
      topStores: topStores.map((s) => ({ ...s, orders: Number(s.orders), revenue: Number(s.revenue ?? 0) })),
      recentOrders: recent,
    };
  }

  // ───────── Users ─────────

  @Get('users')
  async users(@Query() q: { search?: string; role?: string; status?: string; page?: string; pageSize?: string }) {
    const { page, pageSize, offset } = pageParams(q.page, q.pageSize);
    const where: SQL[] = [];
    if (q.search) {
      where.push(
        or(
          ilike(users.email, `%${q.search}%`),
          ilike(users.firstName, `%${q.search}%`),
          ilike(users.lastName, `%${q.search}%`),
        )!,
      );
    }
    if (q.role) where.push(eq(users.role, q.role as AuthUser['role']));
    if (q.status) where.push(eq(users.status, q.status as 'active' | 'blocked'));
    const condition = where.length ? and(...where) : undefined;

    const [rows, [{ total }]] = await Promise.all([
      this.db
        .select({
          id: users.id,
          firstName: users.firstName,
          lastName: users.lastName,
          email: users.email,
          emailVerified: users.emailVerified,
          role: users.role,
          status: users.status,
          phone: users.phone,
          createdAt: users.createdAt,
          lastLoginAt: users.lastLoginAt,
          orderCount: sql<number>`(select count(*) from "orders" o where o."user_id" = "users"."id")`,
        })
        .from(users)
        .where(condition)
        .orderBy(desc(users.createdAt))
        .limit(pageSize)
        .offset(offset),
      this.db.select({ total: count() }).from(users).where(condition),
    ]);
    return { data: rows.map((r) => ({ ...r, orderCount: Number(r.orderCount) })), total: Number(total), page, pageSize };
  }

  @Get('users/:id')
  async user(@Param('id') id: string) {
    const [row] = await this.db.select().from(users).where(eq(users.id, id)).limit(1);
    const user = orNotFound(row, 'user');
    const [addressRows, paymentRows, recentOrders] = await Promise.all([
      this.db
        .select()
        .from(addresses)
        .where(and(eq(addresses.userId, id), eq(addresses.isDeleted, false)))
        .orderBy(desc(addresses.isDefault)),
      this.db
        .select()
        .from(paymentMethods)
        .where(and(eq(paymentMethods.userId, id), eq(paymentMethods.isDeleted, false))),
      this.orderRows(eq(orders.userId, id), 20, 0),
    ]);
    const { passwordHash: _hidden, ...safe } = user;
    return { ...safe, addresses: addressRows, paymentMethods: paymentRows, orders: recentOrders };
  }

  @Patch('users/:id')
  async updateUser(@CurrentUser() me: AuthUser, @Param('id') id: string, @Body() dto: UpdateUserDto) {
    if (dto.role && me.role !== 'admin') throw new BadRequestException('Only admins can change roles.');
    if (id === me.id && (dto.status === 'blocked' || (dto.role && dto.role !== 'admin'))) {
      throw new BadRequestException('You can’t block yourself or remove your own admin access.');
    }
    const [row] = await this.db.update(users).set(dto).where(eq(users.id, id)).returning();
    const user = orNotFound(row, 'user');
    if (dto.status === 'blocked') {
      await this.db
        .update(refreshTokens)
        .set({ revokedAt: new Date() })
        .where(and(eq(refreshTokens.userId, id), isNull(refreshTokens.revokedAt)));
    }
    return { ...toUserJson(user), role: user.role, status: user.status, phone: user.phone };
  }

  /** Adds a saved card or cash option to a customer (for testing until a payment provider exists). */
  @Post('users/:id/payment-methods')
  async addPaymentMethod(@Param('id') id: string, @Body() dto: AddPaymentMethodDto) {
    const [user] = await this.db.select({ id: users.id }).from(users).where(eq(users.id, id)).limit(1);
    orNotFound(user, 'user');
    const [existing] = await this.db
      .select({ n: count() })
      .from(paymentMethods)
      .where(and(eq(paymentMethods.userId, id), eq(paymentMethods.isDeleted, false)));
    const isDefault = dto.isDefault ?? Number(existing.n) === 0;
    if (isDefault) await this.db.update(paymentMethods).set({ isDefault: false }).where(eq(paymentMethods.userId, id));
    const [row] = await this.db
      .insert(paymentMethods)
      .values({ userId: id, type: dto.type, brand: dto.brand, last4: dto.last4 ?? '', expiry: dto.expiry ?? '', isDefault })
      .returning();
    return row;
  }

  @Delete('payment-methods/:id')
  @HttpCode(204)
  async removePaymentMethod(@Param('id') id: string) {
    const [row] = await this.db
      .update(paymentMethods)
      .set({ isDeleted: true, isDefault: false })
      .where(eq(paymentMethods.id, id))
      .returning();
    orNotFound(row, 'payment method');
  }

  // ───────── Orders ─────────

  @Get('orders')
  async orders(@Query() q: { status?: string; search?: string; storeId?: string; page?: string; pageSize?: string }) {
    const { page, pageSize, offset } = pageParams(q.page, q.pageSize);
    const where: SQL[] = [];
    if (q.status) where.push(inArray(orders.status, q.status.split(',') as OrderStatus[]));
    if (q.storeId) where.push(eq(orders.storeId, q.storeId));
    if (q.search) {
      const term = q.search.replace(/^#/, '');
      where.push(
        or(
          sql`${orders.number}::text = ${term}`,
          ilike(users.email, `%${term}%`),
          ilike(stores.name, `%${term}%`),
        )!,
      );
    }
    const condition = where.length ? and(...where) : undefined;
    const [data, [{ total }]] = await Promise.all([
      this.orderRows(condition, pageSize, offset),
      this.db
        .select({ total: count() })
        .from(orders)
        .innerJoin(users, eq(users.id, orders.userId))
        .innerJoin(stores, eq(stores.id, orders.storeId))
        .where(condition),
    ]);
    return { data, total: Number(total), page, pageSize };
  }

  @Get('orders/:id')
  async order(@Param('id') id: string) {
    const [row] = await this.db
      .select({
        order: orders,
        storeName: stores.name,
        storeAddressText: stores.address,
        customerName: sql<string>`${users.firstName} || ' ' || ${users.lastName}`,
        customerEmail: users.email,
        paymentBrand: paymentMethods.brand,
        paymentLast4: paymentMethods.last4,
        paymentType: paymentMethods.type,
      })
      .from(orders)
      .innerJoin(stores, eq(stores.id, orders.storeId))
      .innerJoin(users, eq(users.id, orders.userId))
      .leftJoin(paymentMethods, eq(paymentMethods.id, orders.paymentMethodId))
      .where(eq(orders.id, id))
      .limit(1);
    const found = orNotFound(row, 'order');
    const [items, events] = await Promise.all([
      this.db.select().from(orderItems).where(eq(orderItems.orderId, id)),
      this.db.select().from(orderEvents).where(eq(orderEvents.orderId, id)).orderBy(asc(orderEvents.createdAt)),
    ]);
    return {
      ...found.order,
      storeName: found.storeName,
      storeAddress: found.storeAddressText,
      customerName: found.customerName,
      customerEmail: found.customerEmail,
      payment: found.paymentBrand
        ? { type: found.paymentType, brand: found.paymentBrand, last4: found.paymentLast4 }
        : null,
      items,
      events,
      allowedNextStatuses: TRANSITIONS[found.order.status],
    };
  }

  @Patch('orders/:id/status')
  async updateOrderStatus(@CurrentUser() me: AuthUser, @Param('id') id: string, @Body() dto: UpdateOrderStatusDto) {
    const [order] = await this.db.select().from(orders).where(eq(orders.id, id)).limit(1);
    const current = orNotFound(order, 'order');
    if (!TRANSITIONS[current.status].includes(dto.status)) {
      throw new BadRequestException(`An order that is "${current.status}" can’t be changed to "${dto.status}".`);
    }
    if (dto.status === 'cancelled' && !dto.cancelReason) {
      throw new BadRequestException('Add a cancel reason — the customer will see it.');
    }
    const now = new Date();
    await this.db.transaction(async (tx) => {
      await tx
        .update(orders)
        .set({
          status: dto.status,
          statusNote: dto.note ?? null,
          courierName: dto.courierName ?? current.courierName,
          courierInfo: dto.courierInfo ?? current.courierInfo,
          ...(dto.status === 'pending' && current.status === 'awaitingPayment' ? { paidAt: now } : {}),
          ...(dto.status === 'delivered' ? { deliveredAt: now } : {}),
          ...(dto.status === 'cancelled' ? { cancelledAt: now, cancelReason: dto.cancelReason } : {}),
        })
        .where(eq(orders.id, id));
      await tx.insert(orderEvents).values({
        orderId: id,
        status: dto.status,
        actor: `admin:${me.email}`,
        note: dto.status === 'cancelled' ? dto.cancelReason : dto.note,
      });
    });
    return this.order(id);
  }

  // ───────── Rides ─────────

  @Get('rides')
  async rides(@Query() q: { status?: string; page?: string; pageSize?: string }) {
    const { page, pageSize, offset } = pageParams(q.page, q.pageSize);
    const condition = q.status ? eq(rides.status, q.status as 'requested') : undefined;
    const [rows, [{ total }]] = await Promise.all([
      this.db
        .select({
          ride: rides,
          vehicle: vehicleTypes.name,
          customerEmail: users.email,
          customerName: sql<string>`${users.firstName} || ' ' || ${users.lastName}`,
        })
        .from(rides)
        .innerJoin(vehicleTypes, eq(vehicleTypes.id, rides.vehicleTypeId))
        .innerJoin(users, eq(users.id, rides.userId))
        .where(condition)
        .orderBy(desc(rides.createdAt))
        .limit(pageSize)
        .offset(offset),
      this.db.select({ total: count() }).from(rides).where(condition),
    ]);
    return {
      data: rows.map((r) => ({ ...r.ride, vehicle: r.vehicle, customerEmail: r.customerEmail, customerName: r.customerName })),
      total: Number(total),
      page,
      pageSize,
    };
  }

  @Patch('rides/:id')
  async updateRide(@Param('id') id: string, @Body() dto: UpdateRideDto) {
    const [row] = await this.db.update(rides).set({ status: dto.status }).where(eq(rides.id, id)).returning();
    return orNotFound(row, 'ride');
  }

  // ───────── Services & vehicle types ─────────

  @Get('services')
  servicesList() {
    return this.db.select().from(services).orderBy(asc(services.sortOrder), asc(services.name));
  }

  @Post('services')
  async createService(@Body() dto: ServiceDto) {
    return this.insertUnique(() => this.db.insert(services).values(dto).returning());
  }

  @Patch('services/:id')
  async updateService(@Param('id') id: string, @Body() dto: UpdateServiceDto) {
    const { id: _ignored, ...patch } = dto;
    const [row] = await this.db.update(services).set(patch).where(eq(services.id, id)).returning();
    return orNotFound(row, 'service');
  }

  @Delete('services/:id')
  @HttpCode(204)
  async deleteService(@Param('id') id: string) {
    orNotFound((await this.db.delete(services).where(eq(services.id, id)).returning())[0], 'service');
  }

  @Get('vehicle-types')
  vehicleTypesList() {
    return this.db.select().from(vehicleTypes).orderBy(asc(vehicleTypes.sortOrder), asc(vehicleTypes.name));
  }

  @Post('vehicle-types')
  async createVehicleType(@Body() dto: VehicleTypeDto) {
    return this.insertUnique(() => this.db.insert(vehicleTypes).values(dto).returning());
  }

  @Patch('vehicle-types/:id')
  async updateVehicleType(@Param('id') id: string, @Body() dto: UpdateVehicleTypeDto) {
    const { id: _ignored, ...patch } = dto;
    const [row] = await this.db.update(vehicleTypes).set(patch).where(eq(vehicleTypes.id, id)).returning();
    return orNotFound(row, 'vehicle type');
  }

  @Delete('vehicle-types/:id')
  @HttpCode(204)
  async deleteVehicleType(@Param('id') id: string) {
    const [{ n }] = await this.db.select({ n: count() }).from(rides).where(eq(rides.vehicleTypeId, id));
    if (Number(n) > 0) throw new BadRequestException('This vehicle type has rides, so turn off “Active” instead.');
    orNotFound((await this.db.delete(vehicleTypes).where(eq(vehicleTypes.id, id)).returning())[0], 'vehicle type');
  }

  // ───────── Settings ─────────

  @Get('settings')
  getSettings() {
    return this.settings.get();
  }

  @Roles('admin')
  @Put('settings')
  updateSettings(@Body() dto: SettingsDto) {
    return this.settings.update(dto);
  }

  // ───────── Uploads ─────────

  @Post('uploads')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        const ok = /^image\/(jpeg|png|webp|gif)$/.test(file.mimetype);
        cb(ok ? null : new BadRequestException('Upload a JPG, PNG, WebP or GIF image.'), ok);
      },
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          mkdirSync(env().uploadDir, { recursive: true });
          cb(null, env().uploadDir);
        },
        filename: (_req, file, cb) =>
          cb(null, `${Date.now()}-${randomBytes(6).toString('hex')}${extname(file.originalname).toLowerCase() || '.jpg'}`),
      }),
    }),
  )
  upload(@UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Choose an image to upload.');
    return { url: `${env().publicBaseUrl}/uploads/${file.filename}` };
  }

  // ───────── Helpers ─────────

  private async orderRows(condition: SQL | undefined, limit: number, offset: number) {
    const rows = await this.db
      .select({
        id: orders.id,
        number: orders.number,
        status: orders.status,
        total: orders.total,
        createdAt: orders.createdAt,
        storeName: stores.name,
        customerName: sql<string>`${users.firstName} || ' ' || ${users.lastName}`,
        customerEmail: users.email,
        itemCount: sql<number>`(select coalesce(sum(${orderItems.quantity}), 0) from ${orderItems} where ${orderItems.orderId} = ${orders.id})`,
      })
      .from(orders)
      .innerJoin(users, eq(users.id, orders.userId))
      .innerJoin(stores, eq(stores.id, orders.storeId))
      .where(condition)
      .orderBy(desc(orders.createdAt))
      .limit(limit)
      .offset(offset);
    return rows.map((r) => ({ ...r, itemCount: Number(r.itemCount) }));
  }

  private async insertUnique<T>(insert: () => Promise<T[]>) {
    try {
      return (await insert())[0];
    } catch (e) {
      if (isUniqueViolation(e)) throw new BadRequestException('An item with this id already exists.');
      throw e;
    }
  }
}

