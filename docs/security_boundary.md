# Security Boundary
## Future Times Events — Flutter Client Security Rules

---

## What Flutter MAY Do

- Call Supabase with `SUPABASE_ANON_KEY` (public, row-level-security enforced)
- Call authenticated Supabase RPCs with the user's JWT
- Read published events (public access via RLS)
- Read own profile via `get_my_profile` RPC
- Read own tickets via RLS (`tickets.user_id = auth.uid()`)
- Generate a cryptographically-secure random token locally
- Compute SHA-256 of the raw token and send the hash to `claim_ticket_atomic`
- Embed the raw token in a QR widget (never store or log it)
- Send `qr_token_hash` to `verify_and_checkin` RPC (scanner only)
- Call `claim_ticket_atomic` / `claim_tickets_batch_atomic` for free tickets
- Poll or subscribe to own order/ticket status changes
- Display server-confirmed payment status
- Call Supabase Edge Function for EcoCash initiation (the function holds the Paynow key)

## What Flutter Must NEVER Do

| Prohibited Action | Why |
|-------------------|-----|
| Store `SUPABASE_SERVICE_ROLE_KEY` | Bypasses all RLS |
| Store Paynow integration key | Server secret — payment fraud risk |
| Call Paynow API directly | Server-side only |
| Mark an order as paid | Server-only financial operation |
| Generate a ticket locally | Server must issue tickets after payment confirmation |
| Insert rows into `audit_logs` | Append-only — server responsibility |
| Insert rows into `notification_jobs` | Server-only |
| Set role in user metadata to admin/organizer | Privilege escalation |
| Trust client-sent prices for checkout | Server calculates totals |
| Display QR for revoked/cancelled tickets as valid | Ticket status must come from server |
| Log raw QR tokens | Security — tokens authenticate entry |
| Log full auth JWT | Security |
| Hardcode any admin UIDs | Security |
| Call `is_active_platform_admin` and branch UI solely on result without server check | Defense in depth |
| Force-push to Git | Preserves history |
| Commit keystore / certs / signing keys | Must be in .gitignore |

## Configuration — Mobile-Safe Only

```
SUPABASE_URL        = https://xxx.supabase.co     (--dart-define)
SUPABASE_ANON_KEY   = eyJ...                      (--dart-define, public anon key only)
APP_BASE_URL        = https://futuretimes.events   (--dart-define)
```

All passed as `--dart-define` compile-time constants, never in committed source.

## QR Token Security Architecture

```
Flutter (free ticket claim):
  1. crypto.getRandomBytes(32) → raw_token (UUID or 32-byte random)
  2. SHA-256(raw_token)        → qr_token_hash
  3. call claim_ticket_atomic(... p_qr_token_hash: hash ...)
  4. Server returns {success: true, ticket_number: "FT-0001"}
  5. Flutter stores raw_token in secure storage (NOT shared prefs)
  6. QR widget receives raw_token — displays QR only, never logs value

Scanner (authorized staff only):
  1. Camera reads QR → raw_token string
  2. Flutter: SHA-256(raw_token) → hash
  3. call verify_and_checkin(p_token_hash: hash, p_event_id: ..., p_scanner_id: user.id)
  4. Server: compares hash against tickets.qr_token_hash
  5. Returns scan result — Flutter displays result
```

## RLS Policy Summary (from migrations)

- Profiles: users read own row only
- Events: published events readable by all; draft/cancelled blocked
- Tickets: user reads own tickets only (user_id = auth.uid())
- ticket_scans: staff can insert; staff/admin can read for their event
- event_staff: readable by assigned user and admin
- audit_logs: insert-only for server functions; no client update/delete
