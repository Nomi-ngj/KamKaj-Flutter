# KamKaj Pro — Admin panel

Next.js (React + TypeScript + Tailwind) panel for running the app: orders, stores, products, categories,
customers, rides, services and settings. It only talks to the API in [`../backend`](../backend).

## Run it (staging)

Start the API first (see `backend/README.md`), then:

```bash
cd admin
npm install
npm run dev:staging
```

Open <http://localhost:3001> and sign in with `admin@kamkaj.app` / `Admin@12345`
(or `staff@kamkaj.app` / `Staff@12345` for the restricted staff role).

The orange bar at the top shows you're on staging. Settings live in `env/staging.env`.

## What you can do

| Page | |
|---|---|
| Dashboard | Today's orders and revenue, active orders, 14-day revenue chart, top stores, latest orders |
| Orders | Filter by status, search by number, email or store. Open one to mark it paid, send it out (courier details), deliver or cancel (with a reason the customer sees). Every change is logged in the history |
| Stores | Create and edit stores, including location (lat/lng with a map preview), **delivery radius**, hours (overnight supported), fees, featured/active, categories and image upload |
| Products | Per-store menus: price, section, unit, stock on/off, daily pick, image |
| Categories | Name, icon key, tint, featured, order |
| Customers | Search, block/unblock (signs them out at once), change roles (admin only), see addresses, cards and orders, add test payment methods |
| Rides | Ride requests from the app; change their status |
| Services & vehicles | What appears on the Services tab |
| Settings | Search radius, default city location, free-delivery threshold, service fee (admin only) |

## Going live

```bash
cp env/production.env.example env/production.env   # set NEXT_PUBLIC_API_URL to the live API
npm ci
npm run build:production
npm run start:production                            # or deploy the folder to Vercel
```

Also add the panel's live URL to `CORS_ORIGINS` in the API's `.env.production`. Create the first live admin
with `npm run admin:create:production` in `backend/`; production has no seed accounts.

## Code layout

```
admin/
├── app/login/               sign-in page
├── app/(panel)/             every page behind sign-in (layout.tsx = sidebar + auth check)
├── components/ui.tsx        buttons, inputs, cards, tables, modal…
├── components/extras.tsx    image upload, map preview, bar chart
├── lib/api.ts               API calls, token storage and auto-refresh
└── env/                     staging.env / production.env
```
