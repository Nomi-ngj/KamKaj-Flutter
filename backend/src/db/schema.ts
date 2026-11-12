/**
 * KamKaj Pro database schema (Drizzle ORM → PostgreSQL).
 *
 * - Money is stored in minor units (paisa): 65000 = PKR 650.
 * - Coordinates are WGS84 degrees. Distances use the haversine formula (see geo.ts),
 *   so no PostGIS extension is needed.
 *
 * After changing this file run `npm run db:generate` to create a SQL migration.
 */
import { randomBytes } from 'node:crypto';
import { relations, sql } from 'drizzle-orm';
import {
  boolean,
  doublePrecision,
  index,
  integer,
  pgEnum,
  pgTable,
  primaryKey,
  serial,
  text,
  timestamp,
  uniqueIndex,
} from 'drizzle-orm/pg-core';

/** Short, URL-safe, prefixed ids such as `u_k3j9x0a1b2c3d4e5`. */
export function newId(prefix: string): string {
  return `${prefix}_${randomBytes(12).toString('base64url').toLowerCase().replace(/[-_]/g, 'x')}`;
}

const id = (prefix: string) =>
  text('id')
    .primaryKey()
    .$defaultFn(() => newId(prefix));
const createdAt = () => timestamp('created_at', { withTimezone: true }).notNull().defaultNow();
const updatedAt = () =>
  timestamp('updated_at', { withTimezone: true })
    .notNull()
    .defaultNow()
    .$onUpdate(() => new Date());

// ───────────────────────────── Enums ─────────────────────────────

export const userRole = pgEnum('user_role', ['customer', 'staff', 'admin']);
export const userStatus = pgEnum('user_status', ['active', 'blocked']);
export const codePurpose = pgEnum('code_purpose', ['signUp', 'resetPassword']);
export const categoryTint = pgEnum('category_tint', ['red', 'green', 'yellow', 'blue', 'purple']);
export const addressType = pgEnum('address_type', ['home', 'work', 'other']);
export const paymentMethodType = pgEnum('payment_method_type', ['card', 'cash']);
export const orderStatus = pgEnum('order_status', [
  'awaitingPayment',
  'pending',
  'inTransit',
  'delivered',
  'cancelled',
]);
export const rideStatus = pgEnum('ride_status', [
  'requested',
  'accepted',
  'inProgress',
  'completed',
  'cancelled',
]);

export type OrderStatus = (typeof orderStatus.enumValues)[number];
export type UserRole = (typeof userRole.enumValues)[number];

// ───────────────────────────── Users & auth ─────────────────────────────

export const users = pgTable(
  'users',
  {
    id: id('u'),
    firstName: text('first_name').notNull(),
    lastName: text('last_name').notNull(),
    email: text('email').notNull(),
    passwordHash: text('password_hash').notNull(),
    emailVerified: boolean('email_verified').notNull().default(false),
    role: userRole('role').notNull().default('customer'),
    status: userStatus('status').notNull().default('active'),
    phone: text('phone'),
    lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [uniqueIndex('users_email_key').on(t.email), index('users_role_idx').on(t.role)],
);

export const verificationCodes = pgTable(
  'verification_codes',
  {
    id: id('vc'),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    purpose: codePurpose('purpose').notNull(),
    codeHash: text('code_hash').notNull(),
    attempts: integer('attempts').notNull().default(0),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    usedAt: timestamp('used_at', { withTimezone: true }),
    createdAt: createdAt(),
  },
  (t) => [index('verification_codes_user_purpose_idx').on(t.userId, t.purpose)],
);

export const refreshTokens = pgTable(
  'refresh_tokens',
  {
    id: id('rt'),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    tokenHash: text('token_hash').notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    userAgent: text('user_agent'),
    createdAt: createdAt(),
  },
  (t) => [uniqueIndex('refresh_tokens_hash_key').on(t.tokenHash), index('refresh_tokens_user_idx').on(t.userId)],
);

// ───────────────────────────── Catalog ─────────────────────────────

export const categories = pgTable('categories', {
  id: id('cat'),
  name: text('name').notNull(),
  subtitle: text('subtitle').notNull().default(''),
  icon: text('icon').notNull().default('store'),
  tint: categoryTint('tint').notNull().default('red'),
  featured: boolean('featured').notNull().default(false),
  sortOrder: integer('sort_order').notNull().default(0),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const stores = pgTable(
  'stores',
  {
    id: id('s'),
    name: text('name').notNull(),
    categoryLabel: text('category_label').notNull().default(''),
    tagline: text('tagline'),
    address: text('address').notNull(),
    city: text('city').notNull().default(''),
    latitude: doublePrecision('latitude').notNull(),
    longitude: doublePrecision('longitude').notNull(),
    deliveryRadiusKm: doublePrecision('delivery_radius_km').notNull().default(5),
    rating: doublePrecision('rating').notNull().default(0),
    deliveryTime: text('delivery_time').notNull().default('20-30 min'),
    deliveryFee: integer('delivery_fee').notNull().default(10000),
    imageUrl: text('image_url'),
    /** "09:00" / "21:00" in 24h local time (Asia/Karachi). Null = always open. */
    opensAt: text('opens_at'),
    closesAt: text('closes_at'),
    menuSections: text('menu_sections').array().notNull().default(sql`'{}'::text[]`),
    isFeatured: boolean('is_featured').notNull().default(false),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [index('stores_lat_lng_idx').on(t.latitude, t.longitude), index('stores_active_idx').on(t.isActive)],
);

export const storeCategories = pgTable(
  'store_categories',
  {
    storeId: text('store_id')
      .notNull()
      .references(() => stores.id, { onDelete: 'cascade' }),
    categoryId: text('category_id')
      .notNull()
      .references(() => categories.id, { onDelete: 'cascade' }),
  },
  (t) => [primaryKey({ columns: [t.storeId, t.categoryId] }), index('store_categories_category_idx').on(t.categoryId)],
);

export const products = pgTable(
  'products',
  {
    id: id('p'),
    storeId: text('store_id')
      .notNull()
      .references(() => stores.id, { onDelete: 'cascade' }),
    name: text('name').notNull(),
    description: text('description').notNull().default(''),
    shortDescription: text('short_description'),
    price: integer('price').notNull(),
    section: text('section'),
    unit: text('unit'),
    imageUrl: text('image_url'),
    isDailyPick: boolean('is_daily_pick').notNull().default(false),
    isAvailable: boolean('is_available').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [index('products_store_idx').on(t.storeId), index('products_daily_pick_idx').on(t.isDailyPick)],
);

// ───────────────────────────── Addresses ─────────────────────────────

export const addresses = pgTable(
  'addresses',
  {
    id: id('a'),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: addressType('type').notNull().default('home'),
    label: text('label').notNull(),
    street: text('street').notNull(),
    city: text('city').notNull().default(''),
    apartment: text('apartment'),
    driverNotes: text('driver_notes'),
    latitude: doublePrecision('latitude'),
    longitude: doublePrecision('longitude'),
    isDefault: boolean('is_default').notNull().default(false),
    isDeleted: boolean('is_deleted').notNull().default(false),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [index('addresses_user_idx').on(t.userId)],
);

// ───────────────────────────── Payments ─────────────────────────────

export const paymentMethods = pgTable(
  'payment_methods',
  {
    id: id('pm'),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: paymentMethodType('type').notNull().default('card'),
    brand: text('brand').notNull(),
    last4: text('last4').notNull().default(''),
    expiry: text('expiry').notNull().default(''),
    /** Token from the card provider (Stripe/PayFast…) once one is chosen. */
    providerToken: text('provider_token'),
    isDefault: boolean('is_default').notNull().default(false),
    isDeleted: boolean('is_deleted').notNull().default(false),
    createdAt: createdAt(),
  },
  (t) => [index('payment_methods_user_idx').on(t.userId)],
);

// ───────────────────────────── Orders ─────────────────────────────

export const orders = pgTable(
  'orders',
  {
    id: id('o'),
    number: serial('number').notNull(),
    userId: text('user_id')
      .notNull()
      .references(() => users.id),
    storeId: text('store_id')
      .notNull()
      .references(() => stores.id),
    addressId: text('address_id').references(() => addresses.id, { onDelete: 'set null' }),
    paymentMethodId: text('payment_method_id').references(() => paymentMethods.id, { onDelete: 'set null' }),
    status: orderStatus('status').notNull().default('pending'),
    /** Snapshots so history stays correct when a store or address changes later. */
    fromText: text('from_text').notNull(),
    toText: text('to_text').notNull(),
    distanceKm: doublePrecision('distance_km'),
    subtotal: integer('subtotal').notNull(),
    deliveryFee: integer('delivery_fee').notNull(),
    serviceFee: integer('service_fee').notNull(),
    total: integer('total').notNull(),
    courierName: text('courier_name'),
    courierInfo: text('courier_info'),
    statusNote: text('status_note'),
    cancelReason: text('cancel_reason'),
    estimatedAt: timestamp('estimated_at', { withTimezone: true }),
    paidAt: timestamp('paid_at', { withTimezone: true }),
    deliveredAt: timestamp('delivered_at', { withTimezone: true }),
    cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex('orders_number_key').on(t.number),
    index('orders_user_status_idx').on(t.userId, t.status),
    index('orders_status_idx').on(t.status),
    index('orders_store_idx').on(t.storeId),
  ],
);

export const orderItems = pgTable(
  'order_items',
  {
    id: id('oi'),
    orderId: text('order_id')
      .notNull()
      .references(() => orders.id, { onDelete: 'cascade' }),
    productId: text('product_id').references(() => products.id, { onDelete: 'set null' }),
    productName: text('product_name').notNull(),
    unitPrice: integer('unit_price').notNull(),
    quantity: integer('quantity').notNull(),
    note: text('note'),
    lineTotal: integer('line_total').notNull(),
  },
  (t) => [index('order_items_order_idx').on(t.orderId)],
);

export const orderEvents = pgTable(
  'order_events',
  {
    id: id('oe'),
    orderId: text('order_id')
      .notNull()
      .references(() => orders.id, { onDelete: 'cascade' }),
    status: orderStatus('status').notNull(),
    note: text('note'),
    /** "customer" | "admin:<email>" | "system" */
    actor: text('actor').notNull(),
    createdAt: createdAt(),
  },
  (t) => [index('order_events_order_idx').on(t.orderId)],
);

// ───────────────────────────── Services & rides ─────────────────────────────

export const services = pgTable('services', {
  id: id('sv'),
  name: text('name').notNull(),
  image: text('image').notNull().default(''),
  sortOrder: integer('sort_order').notNull().default(0),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const vehicleTypes = pgTable('vehicle_types', {
  id: id('vt'),
  name: text('name').notNull(),
  image: text('image').notNull().default(''),
  capacity: text('capacity').notNull().default(''),
  baseFare: integer('base_fare').notNull().default(0),
  perKmFare: integer('per_km_fare').notNull().default(0),
  sortOrder: integer('sort_order').notNull().default(0),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const rides = pgTable(
  'rides',
  {
    id: id('ride'),
    userId: text('user_id')
      .notNull()
      .references(() => users.id),
    vehicleTypeId: text('vehicle_type_id')
      .notNull()
      .references(() => vehicleTypes.id),
    status: rideStatus('status').notNull().default('requested'),
    pickupLat: doublePrecision('pickup_lat'),
    pickupLng: doublePrecision('pickup_lng'),
    dropoffLat: doublePrecision('dropoff_lat'),
    dropoffLng: doublePrecision('dropoff_lng'),
    note: text('note'),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [index('rides_status_idx').on(t.status)],
);

// ───────────────────────────── Settings ─────────────────────────────

/** Single row (id = "global") edited from the admin panel. */
export const appSettings = pgTable('app_settings', {
  id: text('id').primaryKey().default('global'),
  /** Stores further than this from the customer are never shown. */
  searchRadiusKm: doublePrecision('search_radius_km').notNull().default(10),
  /** Used when the request has no location and the user has no default address with coordinates. */
  defaultLatitude: doublePrecision('default_latitude').notNull().default(24.8607),
  defaultLongitude: doublePrecision('default_longitude').notNull().default(67.0011),
  defaultCityName: text('default_city_name').notNull().default('Karachi'),
  freeDeliveryThreshold: integer('free_delivery_threshold').notNull().default(100000),
  serviceFee: integer('service_fee').notNull().default(15000),
  nearbyLimit: integer('nearby_limit').notNull().default(10),
  supportPhone: text('support_phone'),
  updatedAt: updatedAt(),
});

// ───────────────────────────── Relations ─────────────────────────────

export const usersRelations = relations(users, ({ many }) => ({
  addresses: many(addresses),
  orders: many(orders),
  paymentMethods: many(paymentMethods),
}));

export const storesRelations = relations(stores, ({ many }) => ({
  categories: many(storeCategories),
  products: many(products),
}));

export const storeCategoriesRelations = relations(storeCategories, ({ one }) => ({
  store: one(stores, { fields: [storeCategories.storeId], references: [stores.id] }),
  category: one(categories, { fields: [storeCategories.categoryId], references: [categories.id] }),
}));

export const productsRelations = relations(products, ({ one }) => ({
  store: one(stores, { fields: [products.storeId], references: [stores.id] }),
}));

export const ordersRelations = relations(orders, ({ one, many }) => ({
  user: one(users, { fields: [orders.userId], references: [users.id] }),
  store: one(stores, { fields: [orders.storeId], references: [stores.id] }),
  items: many(orderItems),
  events: many(orderEvents),
}));

export const orderItemsRelations = relations(orderItems, ({ one }) => ({
  order: one(orders, { fields: [orderItems.orderId], references: [orders.id] }),
}));

export const orderEventsRelations = relations(orderEvents, ({ one }) => ({
  order: one(orders, { fields: [orderEvents.orderId], references: [orders.id] }),
}));

export const addressesRelations = relations(addresses, ({ one }) => ({
  user: one(users, { fields: [addresses.userId], references: [users.id] }),
}));

export const paymentMethodsRelations = relations(paymentMethods, ({ one }) => ({
  user: one(users, { fields: [paymentMethods.userId], references: [users.id] }),
}));

export const ridesRelations = relations(rides, ({ one }) => ({
  user: one(users, { fields: [rides.userId], references: [users.id] }),
  vehicleType: one(vehicleTypes, { fields: [rides.vehicleTypeId], references: [vehicleTypes.id] }),
}));
