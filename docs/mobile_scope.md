# Mobile Scope
## Future Times Events — MVP vs Phase 2 vs Web-Only Classification

---

## MVP (Phase 1–6 — Core Customer Journey)

| Screen | Route | Role | Priority |
|--------|-------|------|----------|
| Splash | `/` | Public | P1 |
| Onboarding (3 screens) | `/onboarding` | Public | P1 |
| Home | `/home` | Public | P1 |
| Browse Events | `/events` | Public | P1 |
| Event Search | `/events/search` | Public | P1 |
| Event Details | `/events/:slug` | Public | P1 |
| Sign In | `/auth/login` | Public | P1 |
| Sign Up | `/auth/signup` | Public | P1 |
| Email Verification | `/auth/verify` | Public | P1 |
| Forgot Password | `/auth/forgot` | Public | P1 |
| My Tickets | `/tickets` | Attendee | P1 |
| Ticket Details + QR | `/tickets/:id` | Attendee | P1 |
| Ticket Selection | `/events/:slug/tickets` | Attendee | P1 |
| Free Ticket Claim | `/checkout/free` | Attendee | P1 |
| EcoCash Checkout | `/checkout/pay` | Attendee | P1 |
| Payment Status | `/checkout/status` | Attendee | P1 |
| Profile | `/profile` | Attendee | P1 |
| Settings | `/settings` | Attendee | P1 |

## Phase 2

| Screen | Route | Role | Priority |
|--------|-------|------|----------|
| Event Map | `/map` | Public | P2 |
| Nearby Events | `/events/nearby` | Public (location) | P2 |
| Referral Wallet | `/referrals` | Attendee | P2 |
| Payout Request | `/referrals/payout` | Attendee | P2 |
| QR Scanner | `/scanner` | Staff | P2 |
| Organizer Dashboard | `/organizer` | Organizer | P2 |
| Event Sales Summary | `/organizer/events/:id/sales` | Organizer | P2 |
| Notifications | `/notifications` | Attendee | P2 |

## Phase 3

| Screen | Route | Role | Priority |
|--------|-------|------|----------|
| Admin Alerts | `/admin` | Admin | P3 |
| Create Event (mobile) | `/organizer/create` | Organizer | P3 |
| Edit Event (mobile) | `/organizer/events/:id/edit` | Organizer | P3 |

## Web-Only / Web-Preferred

| Feature | Reason |
|---------|--------|
| Full Admin Dashboard | Complex tables, destructive actions — web preferred |
| Event Creation (full form) | Many fields, image upload — better on web |
| Financial Ledger Admin | High-risk — admin web dashboard |
| Payout Processing | Admin manual action — web only |
| Analytics/Recharts | Complex charts — web only |
| BullMQ/Redis workers | Server-side only |
