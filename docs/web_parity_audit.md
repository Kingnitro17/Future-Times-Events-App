# Web Parity Audit
## Future Times Events — Mobile vs Web Feature Mapping

**Audit Date:** 2026-08-06  
**Website Repo:** `future-times-events-web` (Next.js 16 / React 19 / Supabase)  
**Flutter Repo:** `events-distro` → renamed `future_times_events`

---

## 1. Application Framework

| Concern | Website | Flutter App |
|---------|---------|-------------|
| Framework | Next.js 16.2.11 (App Router) | Flutter (Dart SDK ≥3.3.0) |
| Router | Next.js App Router | go_router ^14.6.2 |
| State Management | React Context + hooks | flutter_bloc ^8.1.6 |
| Data Fetching | Supabase-js hooks / RPC | supabase_flutter (to add) |
| Styling | TailwindCSS v4 + CSS variables | Flutter ThemeData |
| Icons | lucide-react | Material Icons + flutter_svg |
| Animations | framer-motion | flutter_animate |
| Internationalisation | None (English-only) | intl ^0.19.0 |
| Testing | node --test (production-ticketing) | flutter_test |
| Deployment | Vercel (Netlify toml also present) | Android APK/AAB + iOS IPA |

---

## 2. Supabase Setup

### Environment variables (website)
```
NEXT_PUBLIC_SUPABASE_URL         → SUPABASE_URL (Flutter: --dart-define)
NEXT_PUBLIC_SUPABASE_ANON_KEY    → SUPABASE_ANON_KEY (Flutter: --dart-define)
```

**Note:** `SUPABASE_SERVICE_ROLE_KEY` is ONLY used in server-side Next.js routes and must NEVER enter Flutter.

### Auth methods confirmed in website
- Email + Password (`signInWithPassword`)
- Email sign-up (`signUp`) — role always locked to `attendee`
- OAuth via `oauth.ts` (Google/Apple — conditionally available)
- Session persistence: Supabase `getSession()` + `onAuthStateChange()`
- Profile bootstrap: `get_my_profile` RPC on first load

---

## 3. Database Tables Identified

Confirmed tables from `types/database.ts` and migrations:

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles — id, display_name, email, phone, role, account_status, loyalty_points, is_vip, total_spent, events_attended |
| `events` | Event listings — id, title, slug, category, status, starts_at, ends_at, venue, city, lat, lng, capacity, attendees, organizer_id |
| `ticket_types` | Per-event ticket types — price, quantity_total, quantity_available, claim_limit_per_contact, claim_opens/closes_at, is_active |
| `ticket_claims` | Ticket claims/orders — attendee info, status (confirmed/cancelled), idempotency_key |
| `tickets` | Issued tickets — ticket_number, qr_token_hash (NEVER expose raw token), status (issued/checked_in/cancelled/revoked) |
| `ticket_scans` | Audit log of every scan attempt — scanner_id, scan_result, scanned_at |
| `event_staff` | Scanner/host assignments — user_id, event_id, role (host/event_manager), gate, is_active |
| `event_faqs` | Event FAQs |
| `event_sponsors` | Event sponsors |
| `event_schedule_items` | Schedule / lineup |
| `event_media` | Event images and videos — is_cover, is_published |
| `attendee_visibility` | Who's going display preferences |
| `notification_jobs` | Email notification queue |
| `audit_logs` | Immutable audit trail (Insert only, Update: never) |

### Views
- `public_profile_cards` — safe public profile display (id, display_name, avatar_url, avatar_color, initials)

---

## 4. RPC Functions (Supabase)

| Function | Args | Returns | Security |
|----------|------|---------|---------|
| `get_my_profile` | — | JSON (profile row) | Row-level: own profile only |
| `get_my_role` | — | string | Own role only |
| `is_active_platform_admin` | — | boolean | Own check |
| `verify_and_checkin` | p_token_hash, p_scanner_id, p_event_id, p_gate? | JSON | Server-side atomic — scanner must be event_staff |
| `get_checkin_stats` | p_event_id | JSON | Staff/admin only |
| `claim_ticket_atomic` | p_event_id, p_ticket_type_id, attendee info, p_qr_token_hash, p_ticket_number | JSON | Server validates capacity, limits, idempotency |
| `claim_tickets_batch_atomic` | batch version | JSON | Same guarantees |

### Critical Security Rules from RPC Analysis
1. `claim_ticket_atomic` expects `p_qr_token_hash` — **Flutter generates SHA-256 of a secure random token, sends only the hash. The raw token is embedded in the QR and never stored in plaintext.**
2. `verify_and_checkin` accepts `p_token_hash` — Flutter scanner sends the hash, server checks against `tickets.qr_token_hash`.
3. All financial operations go through server-side logic. No price/payment manipulation from client.

---

## 5. Authentication Roles

| Role | Access Level |
|------|-------------|
| `attendee` | Default — browse, claim tickets, view own tickets |
| `host` | Event staff — scanner access for assigned events |
| `event_manager` | Organizer — manage own events, view sales, scanner |
| `admin` | Platform admin — all events, financial review, payout approval |
| `super_admin` | Full platform access |

Role normalization: `organizer` → `event_manager`, `user` → `attendee` (website does this, Flutter must match).

---

## 6. Payment Architecture

**Method:** Paynow/EcoCash (Zimbabwe)  
**Integration:** Server-side only (Next.js API routes / Edge Functions)  
**Flow:**
1. Flutter → Supabase Edge Function (authenticated)
2. Edge Function → Paynow API (with secret keys — never in Flutter)
3. Paynow → customer EcoCash prompt
4. Paynow → callback to server
5. Server verifies → marks order paid → issues tickets
6. Flutter polls/subscribes for status update

**Existing Flutter pubspec has `flutter_stripe` — this is WRONG for this product. Stripe is not the payment provider. Must be removed.**

---

## 7. Ticket QR Architecture

- `tickets.qr_token_hash` = SHA-256(raw_token) — stored in DB
- Raw token is returned to client ONCE after successful claim
- Flutter embeds raw token in QR widget (never logs it)
- Scanner reads QR → SHA-256 → sends hash to `verify_and_checkin` RPC
- Server checks hash, marks checked_in, records scan

---

## 8. Scanner Check-in Flow (Website Reference)

From `app/checkin/page.tsx`:
1. Auth check → `get_my_profile` RPC
2. Load `event_staff` assignments
3. Camera scanner or manual input
4. Send to `/api/scan` (Next.js route) → calls `verify_and_checkin` RPC
5. **Flutter equivalent:** Call `verify_and_checkin` RPC directly (since Flutter is authenticated client)
6. Display result: admitted / already scanned / not found / wrong event / cancelled / revoked / not open

**Offline:** Check-in disabled when offline ("Offline — admissions disabled").

---

## 9. Missing from Existing Flutter App

The existing `events-distro` Flutter app:
- Uses Firebase (not Supabase) — must be replaced
- Uses Stripe (not Paynow/EcoCash) — must be removed
- Uses a custom Dio HTTP client hitting an unknown backend
- Has no Supabase client
- Has mock data / Eventbrite API references
- Has no authentication implementation
- Named `event_distro` — must be renamed `future_times_events`
- Dark theme only — website is light mode with accent purple/pink

**Summary: The existing Flutter app is effectively a scaffold. Almost all implementation is new.**
