# KamKaj Pro — API

NestJS + PostgreSQL (Drizzle ORM) backend for the Flutter app. It implements every endpoint in
[`../API_DOCUMENTATION.md`](../API_DOCUMENTATION.md) with the same JSON shapes the app already parses,
plus location-aware home data and the admin API used by [`../admin`](../admin).

## Run it on your Mac (staging)

You need **Node.js 20+** (`node -v`; install with `brew install node`) and your local **PostgreSQL**.

```bash
# 1. Create the staging database (once)
createdb kamkaj_staging

# 2. Install
cd backend
npm install

# 3. Check DATABASE_URL in .env.staging matches your Postgres user/password
#    Homebrew / Postgres.app default: postgresql://<your-mac-username>@localhost:5432/kamkaj_staging

# 4. Create the tables and load the test data
npm run db:migrate:staging
npm run db:seed:staging

# 5. Start the API (auto-reloads when you edit code)
npm run dev:staging
```

- API: <http://localhost:3000/v1> · health check: <http://localhost:3000/health>
- Interactive API docs (try every endpoint in the browser): <http://localhost:3000/docs>

### Point the Flutter app at it

`config/staging.json` already points to `http://localhost:3000/v1` with mock mode off:

```bash
flutter run --dart-define-from-file=config/staging.json
```

The iOS simulator reaches `localhost` directly. The Android emulator needs `http://10.0.2.2:3000/v1`
and a debug-only cleartext setting; a real phone needs your Mac's Wi-Fi IP.

## Test accounts (staging seed)

Every customer password is `Password1`. On staging **every verification code is `123456`**
(`000000` is always wrong, to test the error), and codes are also printed in the server log.

| Account | What it tests |
|---|---|
| `hello@appname.com` | Main demo user. Home address in Clifton, Karachi; office and parents' addresses; Visa •••• 4242, Mastercard •••• 0002 (always declined) and cash; orders in every status (awaiting payment, pending, in transit, cancelled, 12 delivered) |
| `new@appname.com` | Brand-new user: no addresses, cards or orders. Home falls back to the Karachi city centre |
| `far@appname.com` | Lives in Quetta. No stores in range → empty home, `isServiceable: false` |
| `lahore@appname.com` | Lives in Lahore. Only sees the two Lahore stores |
| `pending@appname.com` | Never verified email. Sign-in returns "Please verify your email first"; code `123456` verifies it |
| `blocked@appname.com` | Suspended. Sign-in is refused |
| `admin@kamkaj.app` / `Admin@12345` | Admin panel, full access |
| `staff@kamkaj.app` / `Staff@12345` | Admin panel, staff role (can't change settings or roles) |

### Stores that cover specific cases

| Store | Case |
|---|---|
| The Corner Bakery, The Daily Grind, Main St. Flowers, Green Valley Organics | Near the demo user. Featured stores, daily picks, full menus |
| Night Owl Desserts (18:00–03:00), Morning Bakes (06:00–10:00) | Closed during the day: listed with `isOpen: false`; ordering returns "… is closed right now" |
| CarePlus Pharmacy | Open 24/7 (no hours) |
| Bun Kebab, Chaunsa Mangoes, Jumbo Prawns | Out of stock: shown, but ordering fails with a clear message |
| Stationery Corner | No products (empty store page) |
| Paws & Whiskers | Only delivers around Gulshan: appears for the "Parents" address, refuses orders to Clifton |
| Nazimabad Hardware | Small 4 km radius |
| Malir Farm Store | About 18 km away, outside the 10 km search radius |
| Old Town Grocers | Inactive: never appears in the app (404) |
| Gulberg Bakehouse, Liberty Fresh Mart | Lahore only |

Re-run `npm run db:seed:staging` any time to reset the data. `npm run db:reset:staging` also drops and
recreates every table.

## How the location radius works

Every catalog list (`/home`, `/stores/nearby`, `/stores/featured`, `/stores?category=`, `/products/daily-picks`)
only returns **active stores that deliver to the customer's location**:

- the distance is within the store's own **delivery radius** (set per store in the admin panel), **and**
- it is within the global **search radius** (Settings, default 10 km).

Results are sorted nearest first, and each store includes `distanceKm`. The location is chosen in this order:

1. `?lat=24.81&lng=67.03` sent by the app (selected location or GPS)
2. `?addressId=…`, one of the user's saved addresses
3. the signed-in user's **default address** (if it has coordinates)
4. any other saved address with coordinates
5. the city default from Settings (Karachi)

The app doesn't send a location yet, so today it gets results for the user's default address. Addresses
accept optional `latitude` / `longitude`. When the app adds a location picker, it only needs to send `lat`
and `lng`. `GET /v1/home` returns categories, nearby stores, featured stores and daily picks in one call,
plus `isServiceable`.

Placing an order also checks that the delivery address is inside the store's radius.

## Endpoints added beyond the original contract

| Endpoint | Purpose |
|---|---|
| `GET /home` | Whole home screen in one call (location-aware) |
| `GET /orders/{id}` | Order detail with items and fees |
| `POST /orders/{id}/cancel` | Customer cancels (awaiting payment / pending only) |
| `DELETE /addresses/{id}` | Remove an address (the next one becomes default) |
| `/admin/*` | Everything the admin panel uses (staff/admin only) |

Pricing is now done on the server: delivery is free from PKR 1,000 (configurable), otherwise the store's
fee applies, plus a PKR 150 service fee. Responses include `subtotal`, `deliveryFee`, `serviceFee` and `total`.

## Production

```bash
cp .env.production.example .env.production   # fill in a real DATABASE_URL and two new JWT secrets
npm ci && npm run build
npm run db:migrate:production                  # creates the tables (never seeds)
npm run admin:create:production -- --email you@company.com --password 'a-long-password' --name "Your Name"
npm run start:production
```

Safety rails:
- The seed and reset scripts refuse to run unless `APP_ENV=staging`.
- The API refuses to start in production with weak JWT secrets or with `FIXED_OTP` set.
- API docs (`/docs`) are off in production unless `SWAGGER_ENABLED=true`.

Before going live you still need to:
- connect an email provider in `src/modules/auth/mail.service.ts`, so verification codes are actually sent
- connect a card provider (Stripe / PayFast…) in `OrdersService.place` and `pay`. Cards are only simulated today; card `0002` is declined on staging only
- move image uploads to S3 or Cloudflare R2 if you run more than one server (they're saved to `./uploads` today)

## Project layout

```
backend/
├── drizzle/                 SQL migrations (generated — commit them)
├── scripts/                 migrate, seed (staging), reset (staging), create-admin
├── src/
│   ├── main.ts              start-up, /v1 prefix, validation, CORS, /docs, /uploads
│   ├── app.module.ts        wires everything together
│   ├── config/env.ts        reads and checks environment variables
│   ├── db/schema.ts         ALL TABLES — edit here, then `npm run db:generate`
│   ├── db/geo.ts            distance maths (haversine)
│   ├── common/              auth guard & roles, error format, helpers
│   └── modules/
│       ├── auth/            sign-in/up, codes, refresh tokens, password reset
│       ├── catalog/         categories, stores, products, location resolution
│       ├── addresses/
│       ├── orders/          orders, pricing, payment methods
│       ├── services/        services, vehicle types, ride requests
│       ├── settings/        global settings (radius, fees)
│       └── admin/           admin-only endpoints
├── .env.staging             local staging config
└── .env.production.example  template for live
```

**Changing the database:** edit `src/db/schema.ts`, run `npm run db:generate` (writes a new SQL file to
`drizzle/`), then `npm run db:migrate:staging`. The same files run on production with `db:migrate:production`.

**Errors** always come back as `{ "statusCode": 400, "message": "A sentence the app can show" }`.
**Money** is always paisa (`65000` = PKR 650). **Times** are ISO-8601. Store hours are in Pakistan time.
