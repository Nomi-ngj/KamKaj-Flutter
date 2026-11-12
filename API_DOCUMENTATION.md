# API Documentation

> **Status: backend not available yet.** These are the contracts the app is built against.
> Everything below is served by in-memory mock data sources while `USE_MOCK_API=true`
> (the default). Confirm or adjust them with the backend team, then flip the flag.

## Conventions

- Base URL from `--dart-define=API_BASE_URL` (see `config/*.json`). HTTPS only.
- JSON in/out. Responses may be the object itself or wrapped as `{ "data": … }` — both work.
- Errors: non-2xx with `{ "message": "user-facing text" }`. The message is shown as-is; anything
  else falls back to a generic message.
- Auth: `Authorization: Bearer <accessToken>`. On `401` the client calls `/auth/refresh` once;
  if that fails the user is signed out.
- Money: integers in **minor units** (paisa). `65000` = PKR 650.
- Dates: ISO-8601 strings.

## Endpoints

### Auth
| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/auth/sign-in` | `{email, password}` | `{accessToken, refreshToken, user}` |
| POST | `/auth/sign-up` | `{firstName, lastName, email, password}` | `204` — code emailed |
| POST | `/auth/verify-code` | `{email, code, purpose: "signUp" \| "resetPassword"}` | signUp → `{accessToken, refreshToken, user}`; reset → `{resetToken}` |
| POST | `/auth/resend-code` | `{email, purpose}` | `204` |
| POST | `/auth/forgot-password` | `{email}` | `204` (always, to avoid account enumeration) |
| POST | `/auth/reset-password` | `{resetToken, password}` | `204` |
| POST | `/auth/change-password` | `{currentPassword, newPassword}` | `204` |
| POST | `/auth/refresh` | `{refreshToken}` | `{accessToken, refreshToken}` |
| POST | `/auth/sign-out` | — | `204` |
| GET | `/users/me` | — | `user` |

`user = {id, firstName, lastName, email, emailVerified}`

### Catalog
| Method | Path | Response |
|--------|------|----------|
| GET | `/categories` | `[{id, name, subtitle, icon, tint, featured}]` |
| GET | `/products/daily-picks` | `[product]` |
| GET | `/stores/nearby` | `[store]` |
| GET | `/stores/featured` | `[store]` |
| GET | `/stores?category=<id>` | `[store]` |
| GET | `/stores/{id}` | `store` |
| GET | `/stores/{id}/products` | `[product]` |
| GET | `/products/{id}` | `product` |

`store = {id, name, category, address, rating, deliveryTime, deliveryFee, imageUrl, openUntil, menuSections[], tagline, categoryIds[]}`
`product = {id, storeId, storeName, name, description, shortDescription, price, section, unit, imageUrl}`
`icon` is a key the app maps to an icon (e.g. `food`, `grocery`, `pharmacy` — see `CategoryVisuals`).
`tint` ∈ `red | green | yellow | blue | purple`.

### Addresses
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/addresses` | — | `[address]` |
| POST | `/addresses` | `{type, street, city, apartment?, driverNotes?}` | `address` |
| PUT | `/addresses/{id}` | same | `address` |
| POST | `/addresses/{id}/default` | — | `204` |

`address = {id, type: home|work|other, label, street, city, apartment, driverNotes, isDefault}`

### Orders & payments
| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/orders?scope=current\|past` | — | `[order]` |
| POST | `/orders` | `{storeId, addressId, paymentMethodId, items:[{productId, quantity, note?}]}` | `order` |
| POST | `/orders/{id}/pay` | — | `order` |
| POST | `/orders/{id}/reorder` | — | `order` |
| GET | `/payment-methods` | — | `[{id, brand, last4, expiry}]` |

`order = {id, number, title, status, from, to, deliveryDate, subtitle, amountDue, courierInfo, cancelReason, total}`
`status` ∈ `awaitingPayment | pending | inTransit | delivered | cancelled`.

### Services
| Method | Path | Response |
|--------|------|----------|
| GET | `/services` | `[{id, name, image}]` |
| GET | `/rides/vehicle-types` | `[{id, name, image, capacity}]` |
| POST | `/rides` `{vehicleTypeId}` | `{id}` |

## Pending decisions

- **Pricing** — client currently computes: delivery free from PKR 1,000 else PKR 100, service
  fee PKR 150 (`CalculateCheckoutSummary`). The server should return the authoritative totals.
- **Payments** — card tokenisation provider (Stripe/PayFast/…) not chosen; `/orders/{id}/pay`
  is a placeholder contract.
- **Maps & geocoding** — provider and API key not chosen; address pin is static.
- **Social sign-in** — Apple/Google not configured.
- **Live tracking** — real-time channel (WebSocket/FCM) not defined; tracking shows status steps.

## Adding an endpoint

1. Add the path to `core/network/api_endpoints.dart`.
2. Add a method to the feature's remote data source interface, implement it with `DioClient`
   (`get`, `getList`, `post`, `put`, `patch`, `delete`, `upload`, `download`) and in the mock.
3. Map JSON with `JsonReader` (`json.readString('id')` …) in the feature's mapper.
4. Expose it through the repository (wrap with `ErrorMapper.guard`) and a use case.

`DioClient` converts every `DioException` into an `AppException`; `ErrorMapper` turns that into a
user-safe `Failure`. Request logging is on in development only and never logs headers or bodies.
