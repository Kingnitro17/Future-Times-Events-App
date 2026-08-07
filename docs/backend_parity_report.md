# Backend parity report

Date: 2026-08-07  
Website baseline: `master` at `594930f8d8bdfa8e8c776178270564568eeae371`  
Flutter baseline: `main` at `7a04da4fb01c923bc2b2e213f71e6ce0daca752b`

## Repository safety

- The website repository was inspected read-only and was not modified.
- The Flutter repository was clean before work began.
- Work is isolated on `feature/mobile-v2-production`.

## Production configuration

The website reads `NEXT_PUBLIC_SUPABASE_URL` and
`NEXT_PUBLIC_SUPABASE_ANON_KEY` through `lib/supabase/config.ts`. The production
project host in `.env.local` is `ecbbmcqwluivbzlaqdsd.supabase.co`.

The Flutter app previously had no Supabase dependency or configuration. It now
accepts `SUPABASE_URL` and `SUPABASE_ANON_KEY` through `--dart-define`, validates
that the project identifier is `ecbbmcqwluivbzlaqdsd`, initializes one client,
and never logs the key or tokens.

## Public events

### Website implementation

`lib/useEvents.ts` queries `public.events`, selects:

`id,title,slug,category,category_label,date,time,end_time,venue,address,city,description,long_description,price,attendees,capacity,image_url,mood,tags,featured,lineup,organizer_name,lat,lng`

It filters `status = published` and orders by `date` ascending. Public RLS in
the production migrations permits legitimate public event statuses.

### Previous Flutter implementation

`EventRepository` returned hard-coded Eventbrite-shaped San Francisco events.
The unused network service targeted Eventbrite `events/search/` and depended on
an Eventbrite bearer token. It did not query Future Times or Supabase at all.

### Root cause and correction

The failure was architectural, not an empty database: the mobile app had no
connection to the production backend and incompatible Eventbrite-shaped models.
`SupabaseEventService` now performs the same production select, publication
filter, ordering, search/category/date/price filtering, pagination, and safe row
mapping. A broken optional image no longer prevents an event row from mapping.

### Verification

- Read-only production REST query: PASS, HTTP success, 1 published event.
- Returned event identity/title/status fields: PASS.
- Flutter analyzer: zero errors (pre-existing warnings remain).

## Authentication and profile bootstrap

### Website implementation

`lib/auth-context.tsx` uses one browser client, `signInWithPassword`, one auth
subscription, session-backed bootstrap, and `get_my_profile` for the profile.

### Previous Flutter implementation

There was no Supabase auth code, no login route/action, no session restoration,
and no profile query. The Profile screen's Sign In button had an empty callback.

### Root cause and correction

Login could not work because it was not implemented against any backend.
`AuthRepository` now owns the single listener, restores `currentSession`, handles
stream errors, calls `signInWithPassword`, maps common auth failures, loads
`get_my_profile` only on meaningful session changes, and supports sign-out.
Profile failure does not block public browsing.

### Verification

- Production Auth settings endpoint: PASS; email provider enabled.
- Deliberately invalid credential request: PASS; rejected with HTTP 400.
- Valid account sign-in: NOT YET VERIFIED because no legitimate test account
  credentials were present in either repository. No claim of successful login
  is made until a controlled account is used.

## Current backend contracts

Flutter currently uses:

- Tables: `events`
- RPCs: `get_my_profile`
- Auth: password sign-in, persisted session, sign-out
- Storage buckets: none directly (existing full `image_url` values are rendered)
- Realtime: none
- Edge Functions: none in this milestone

Ticket, order, payment, referral, scanner, and storage parity remain subsequent
backend phases and must use the contracts in the website migrations/functions.

## Safe local run

```text
flutter run --dart-define=SUPABASE_URL=<production-url> --dart-define=SUPABASE_ANON_KEY=<public-key>
```

Do not place service-role, payment, access-token, refresh-token, password, or QR
secrets in Dart source or command output.
