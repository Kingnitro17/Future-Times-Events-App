-- ============================================
-- MIGRATION: Security hardening
-- Fixes Supabase linter warnings:
--   1. RLS enabled with no policies on 3 tables
--   2. Permissive INSERT policies on comments
--   3. Public bucket listing on avatars + events
--   4. Revoke SECURITY DEFINER functions from anon
--   5. Revoke trigger-only functions from client RPC
-- Safe to re-run.
-- ============================================

-- ─────────────────────────────────────────────
-- 1. Add policies to tables with RLS but no rules
-- ─────────────────────────────────────────────

-- attendee_visibility: read-only for signed-in users
alter table public.attendee_visibility enable row level security;

drop policy if exists "Anyone signed in can view attendee visibility" on public.attendee_visibility;
create policy "Anyone signed in can view attendee visibility"
  on public.attendee_visibility for select
  to authenticated
  using (true);

-- audit_logs: super admins only
alter table public.audit_logs enable row level security;

drop policy if exists "Super admins read audit logs" on public.audit_logs;
create policy "Super admins read audit logs"
  on public.audit_logs for select
  to authenticated
  using (public.is_super_admin());

-- notification_jobs: service_role only (no client access)
alter table public.notification_jobs enable row level security;
-- (no policy = no client access, only service_role can touch it)

-- ─────────────────────────────────────────────
-- 2. Fix permissive INSERT on comments
-- ─────────────────────────────────────────────

-- Drop the unrestricted policies
drop policy if exists "Allow inserts" on public.comments;
drop policy if exists "Enable insert for everyone" on public.comments;

-- Only authenticated users can comment, and only as themselves
drop policy if exists "Authenticated users insert own comments" on public.comments;
create policy "Authenticated users insert own comments"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Also make sure updates/deletes are owner-only (belt and braces)
drop policy if exists "Users edit own comments" on public.comments;
create policy "Users edit own comments"
  on public.comments for update
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users delete own comments" on public.comments;
create policy "Users delete own comments"
  on public.comments for delete
  to authenticated
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- 3. Drop broad SELECT on storage for public buckets
-- ─────────────────────────────────────────────

-- Public buckets serve files by URL without a policy.
-- A broad SELECT policy exposes the full file listing.
drop policy if exists "Public avatar images are viewable" on storage.objects;
drop policy if exists "Anyone can view event images" on storage.objects;

-- Optional: keep upload/update/delete rules for owners
drop policy if exists "Users upload own avatars" on storage.objects;
create policy "Users upload own avatars"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users update own avatars" on storage.objects;
create policy "Users update own avatars"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─────────────────────────────────────────────
-- 4. Revoke anon EXECUTE on all SECURITY DEFINER functions
--    Signed-in users keep their access.
-- ─────────────────────────────────────────────

do $$
declare
  r record;
begin
  for r in
    select p.proname,
           pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and p.prosecdef = true  -- SECURITY DEFINER only
  loop
    execute format(
      'revoke execute on function public.%I(%s) from anon',
      r.proname, r.args
    );
  end loop;
end $$;

-- ─────────────────────────────────────────────
-- 5. Revoke trigger-only functions from BOTH anon and authenticated
--    These should only run when a DB trigger fires, not via RPC.
-- ─────────────────────────────────────────────

do $$
declare
  fn text;
  trigger_fns text[] := array[
    'handle_new_user',
    'increment_attendees',
    'notify_new_follower',
    'guard_user_follow',
    'cleanup_social_on_block',
    'prevent_profile_privilege_escalation',
    'protect_event_review_fields',
    'sync_auth_user_profile',
    'sync_public_profile_card',
    'update_user_loyalty',
    'restore_product_preorder_stock',
    'rls_auto_enable'
  ];
  r record;
begin
  for fn in select unnest(trigger_fns) loop
    for r in
      select pg_get_function_identity_arguments(p.oid) as args
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = fn
    loop
      execute format(
        'revoke execute on function public.%I(%s) from anon, authenticated',
        fn, r.args
      );
    end loop;
  end loop;
end $$;

-- ─────────────────────────────────────────────
-- 6. Ensure the client-facing RPCs are still granted to authenticated
--    (re-affirm because step 4 revoked anon, and we want to be explicit)
-- ─────────────────────────────────────────────

do $$
declare
  r record;
  keep_fns text[] := array[
    'get_my_profile','get_my_role','get_my_social_stats','get_my_ticket_wallet',
    'claim_free_ticket','claim_my_free_tickets','claim_tickets_batch_atomic',
    'create_ticket_order_atomic','confirm_order_payment_and_issue_tickets',
    'expire_ticket_reservations','verify_and_checkin','get_checkin_stats',
    'get_event_like_counts','get_event_social_summary','get_event_visible_attendees',
    'is_group_member','is_organizer','is_super_admin','is_active_platform_admin',
    'accept_group_invite','decline_group_invite','create_attendance_group',
    'request_service_booking','cancel_service_booking','confirm_service_booking',
    'check_service_availability','admin_review_service_booking',
    'create_product_preorder','reserve_table','place_venue_order',
    'update_order_status','event_has_ft_service'
  ];
  fn text;
begin
  foreach fn in array keep_fns loop
    for r in
      select pg_get_function_identity_arguments(p.oid) as args
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = fn
    loop
      execute format(
        'grant execute on function public.%I(%s) to authenticated',
        fn, r.args
      );
    end loop;
  end loop;
end $$;

-- ─────────────────────────────────────────────
-- 7. Realtime publication grants (unchanged but verify)
-- ─────────────────────────────────────────────

notify pgrst, 'reload schema';