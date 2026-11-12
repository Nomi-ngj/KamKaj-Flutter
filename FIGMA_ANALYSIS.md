# Figma Analysis

Source: `Nouman Gul Junejo's team library` → page **Main** (`0:1`), file key `9kC9eVbqZ1vW51K57fst2G`.
Artboard width: **440 pt** (most frames), My Orders frame: 390 pt.

> **Inspection note.** Screenshots were captured for 20 of 23 frames. The Figma
> Starter-plan MCP limit was reached before the last three (Saved Addresses ×2 and
> Add New Address) could be rendered, so those were rebuilt from the layer tree
> (names, text, sizes, positions), which was retrieved for every frame.
> Raster images (photos, 3D illustrations) could not be exported — see **Assets**.

## 1. Screen inventory

| # | Frame | Node | Feature module | Route |
|---|-------|------|----------------|-------|
| 1 | Splash | 2315:2 | `splash` | `/splash` |
| 2 | Onboarding – 1/2/3 | 2318:51, 2323:129, 2323:139 | `onboarding` | `/onboarding` |
| 3 | Select Language | 2325:152 | `language` | `/language` |
| 4 | Sign In | 2335:840 | `auth` | `/auth/sign-in` |
| 5 | Sign Up | 2331:357 | `auth` | `/auth/sign-up` |
| 6 | Forgot Password | 2336:1171 | `auth` | `/auth/forgot-password` |
| 7 | Verify Email (OTP) | 2336:1253 | `auth` | `/auth/verify-email` |
| 8 | Reset Password | 2336:1303 | `auth` | `/auth/reset-password` |
| 9 | Change Password | 2337:1346 | `auth` | `/profile/change-password` |
| 10 | Dashboard | 2341:1430 | `dashboard` | `/home` (tab 1) |
| 11 | Categories | 2354:16 | `catalog` | `/explore` (tab 2) |
| 12 | Store Detail | 2359:540 | `catalog` | `/store/:storeId` |
| 13 | Product Detail | 2361:669 | `catalog` | `/product/:productId` |
| 14 | Checkout (step 2 of 3) | 2358:401 | `checkout` | `/checkout` |
| 15 | Saved Addresses | 2389:763 | `address` | `/profile/addresses` |
| 16 | Saved Addresses – confirm default | 2389:854 | `address` | dialog on 15 |
| 17 | Add New Address | 2389:961 | `address` | `/profile/addresses/new` |
| 18 | Home (Services / Book a ride) | 2453:233 | `services` | `/services` |
| 19 | My Orders | 2463:30 | `orders` | `/orders` (tab 3) |
| — | Colour swatches, App Logo | 2318:40 … 2320:104 | design tokens | — |

## 2. Navigation flow

```
Splash ──(first launch)──► Onboarding 1 → 2 → 3 ──► Select Language ──► Sign In
   │                         (Skip ────────────────►)                     │  ├─► Sign Up ──► Verify Email ──► Home
   │                                                                      │  └─► Forgot Password ──► Verify Email ──► Reset Password ──► Sign In
   ├──(onboarded, signed out)──► Sign In
   └──(signed in)──► Shell [Home | Explore | Orders | Profile]

Home(Dashboard) ─► Category ─► Explore (filtered)        Explore ─► Store Detail ─► Product Detail ─► (Add to cart)
Store Detail ─► "View your basket" ─► Checkout ─► Place Order ─► Orders
Profile ─► Saved Addresses ─► (Set default dialog) / Add New Address
Profile ─► Services (ride booking) / Change Password / Language / Sign out
```

## 3. Design tokens (from Figma variables)

| Token | Value |
|-------|-------|
| `PrimaryColor` | `#205695` |
| `SecondaryColor` / `SecondaryLightColor` | `#F97316` |
| `GaryColor` (sic) | `#555555` |
| `BlackColor` / `WhiteColor` | `#000000` / `#FFFFFF` |
| Auth/onboarding background | peach — `#F97316` tint, sampled `#FFE4D6` |
| App background (shop screens) | off-white, sampled `#F8F7F5` |

Typography — family **Poppins**, letter-spacing −2 % on all styles:

| Style | Size / Weight |
|-------|---------------|
| Header 2 | 24 / Bold 700 |
| Subhead | 17 / SemiBold 600 |
| Callout | 16 / Regular 400 |
| Caption 1 | 14 / Regular 400 |
| Caption 1 Med | 14 / Medium 500 |
| Caption 4 Med | 10 / Medium 500 |

Measured components: input 365×56 (radius 8, soft shadow), primary button 365×47 (radius 8),
language button 350×60, onboarding button 298×47, product image 182×206, category tile 69×65,
store hero 440×288, product hero 440×390, address icon 48×48, bottom-bar CTA 400×58.

## 4. Reusable components identified

`AppButton` (primary blue / secondary orange / outline / text), `AppTextField` (with
trailing icon & password toggle), `AppOtpField` (6 boxes), `AppCard`, `AppAppBar`
(back + title + overflow), `AppRatingChip`, `AppTagChip`, `AppSectionHeader`
("Categories … View All"), `AppQuantityStepper`, `AppBottomNavBar`, `AppDialog`
(Set as Default?), `AppNetworkImage`/`AppAssetImage`, `AppLoader`, `AppEmptyView`,
`AppErrorView`, `PageDots`, `StatusBadge`.

## 5. UI interactions

- Onboarding: swipe/“Continue”, “Skip”, page dots; last page “Get Started”.
- Language: single-select list; selected item is primary-blue, others orange.
- Auth: email validation, password visibility toggle, OTP auto-advance, resend countdown (60 s).
- Dashboard: horizontal lists (Fresh Today, Nearby Shops), favourite toggle, store cards.
- Categories: search field filters the grid.
- Store detail: category chips filter menu, “+” adds to basket, floating basket bar.
- Product detail: quantity stepper, special instructions, add to cart, share, favourite.
- Checkout: step indicator, edit address, payment row, summary, place order.
- Addresses: select / set default (confirmation dialog), edit, add new (Save as Home/Work/Other).
- My Orders: Current/Past tabs, Pay Now, Track Live, Re-order.

## 6. Assets required (export from Figma → `assets/images/`)

| File name | Figma node |
|-----------|------------|
| `splash_background.png` | Splash › background image `2316:10` |
| `app_logo.png` | App Logo `2320:104` |
| `onboarding_1.png` | Onboarding‑1 › delivery-package-icon `2320:95` |
| `onboarding_2.png` | Onboarding‑2 › delivery-package-icon `2323:130` |
| `onboarding_3.png` | Onboarding‑3 › delivery-package-icon `2323:140` |
| `map_placeholder.png` | Add New Address › Image `2389:965` |
| `service_express_ride.png`, `service_delivery_package.png` | Home › service cards |
| `vehicle_sedan.png`, `vehicle_van.png`, `vehicle_truck.png` | Home › Book A Ride Now |

Product / store photos are **content** and are loaded from the API (`imageUrl`).
Every image widget falls back to a tokenised placeholder until the file exists.
Icons use Material Symbols (rounded) that match the Figma glyphs.

## 7. Missing design decisions & assumptions

1. **Profile tab** has no frame. A minimal list screen (Saved Addresses, Services,
   Change Password, Language, Sign out) was built purely from existing tokens.
2. **Services (“Home” frame 2453:233)** conflicts with the Dashboard as “home”. Dashboard
   is the Home tab (it owns the bottom bar); Services is reachable from Profile.
3. **Bottom bar**: Dashboard uses Home/Explore/Orders/Profile, My Orders uses
   Home/Orders/Services/Account. The Dashboard version is used app‑wide.
4. **My Orders** frame is an HTML import using Plus Jakarta Sans and `#1E56FF`. It is
   implemented with the app tokens (Poppins, `#205695`) to keep one design system;
   layout, spacing and status colours follow the frame.
5. **Checkout steps 1 & 3** are not designed; the step indicator is shown, step 2 is the
   implemented checkout page, and success returns to Orders.
6. **Maps**: no map SDK/API key is defined. A static map image is shown; pin dragging is
   out of scope until a maps provider is chosen.
7. **Social sign‑in** (Apple, Google) buttons are present; providers are not configured,
   so they show a “coming soon” message.
8. **Localisation**: 5 languages incl. RTL (Arabic, Urdu). Locale + direction switching
   is implemented; translated copy is pending (strings are English).
9. **Dark mode** is not in the design — light theme only (dark theme file mirrors light).
10. **Loading / error / empty states** are not designed; built with existing tokens.
11. **Backend API** is not specified — see `API_DOCUMENTATION.md` for the contracts.
    A mock data source serves the Figma content in development.
12. Typos kept from Figma content are corrected in code (`PRK` → `PKR`).
