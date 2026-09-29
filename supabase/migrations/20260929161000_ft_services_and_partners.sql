-- Future Times service catalog, bookings, event partners, and reminders.
-- Safe to re-run. Apply manually in the Supabase SQL editor.

-- 1. Hireable service catalog
create table if not exists public.ft_services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text not null,
  image_url text,
  base_price numeric(10,2) not null default 0,
  currency text not null default 'USD',
  unit text not null default 'day',
  deposit_percent int not null default 30
    check (deposit_percent between 0 and 100),
  total_quantity int not null default 1
    check (total_quantity > 0),
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ft_services_category_idx
  on public.ft_services(category, sort_order)
  where is_active;

-- A stable natural key makes catalog seeding idempotent without replacing prices.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_services'::regclass
      and conname = 'ft_services_deposit_percent_check'
  ) then
    alter table public.ft_services
      add constraint ft_services_deposit_percent_check
      check (deposit_percent between 0 and 100);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_services'::regclass
      and conname = 'ft_services_total_quantity_check'
  ) then
    alter table public.ft_services
      add constraint ft_services_total_quantity_check
      check (total_quantity > 0);
  end if;
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.ft_services'::regclass
      and conname = 'ft_services_name_uidx'
  ) then
    alter table public.ft_services
      add constraint ft_services_name_uidx unique (name);
  end if;
end;
$$;

-- 2. Organizer bookings
create table if not exists public.ft_service_bookings (
  id uuid primary key default gen_random_uuid(),
  service_id uuid references public.ft_services(id) on delete restrict,
  event_id uuid references public.events(id) on delete cascade,
  organizer_id uuid references public.profiles(id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  start_time timestamptz not null,
  end_time timestamptz not null,
  total_price numeric(10,2) not null,
  deposit_amount numeric(10,2) not null,
  currency text not null default 'USD',
  status text not null default 'draft'
    check (status in (
      'draft', 'pending_payment', 'deposit_paid', 'pending_review',
      'approved', 'rejected', 'active', 'completed', 'cancelled'
    )),
  payment_transaction_id uuid
    references public.payment_transactions(id),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ft_booking_time_check check (end_time > start_time)
);

create index if not exists ft_booking_service_time_idx
  on public.ft_service_bookings(service_id, start_time, end_time)
  where status in ('deposit_paid', 'pending_review', 'approved', 'active');
create index if not exists ft_booking_organizer_idx
  on public.ft_service_bookings(organizer_id, created_at desc);
create index if not exists ft_booking_event_idx
  on public.ft_service_bookings(event_id);
create index if not exists ft_booking_status_idx
  on public.ft_service_bookings(status, created_at desc);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_service_bookings'::regclass
      and conname = 'ft_service_bookings_quantity_check'
  ) then
    alter table public.ft_service_bookings
      add constraint ft_service_bookings_quantity_check check (quantity > 0);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_service_bookings'::regclass
      and conname = 'ft_service_bookings_status_check'
  ) then
    alter table public.ft_service_bookings
      add constraint ft_service_bookings_status_check
      check (status in (
        'draft', 'pending_payment', 'deposit_paid', 'pending_review',
        'approved', 'rejected', 'active', 'completed', 'cancelled'
      ));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_service_bookings'::regclass
      and conname = 'ft_booking_time_check'
  ) then
    alter table public.ft_service_bookings
      add constraint ft_booking_time_check check (end_time > start_time);
  end if;
end;
$$;

-- 3. Event partners
create table if not exists public.event_partners (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.events(id) on delete cascade,
  name text not null,
  logo_url text,
  website_url text,
  tier text not null default 'partner'
    check (tier in ('partner', 'featured_partner', 'official_partner')),
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists event_partners_event_idx
  on public.event_partners(event_id, sort_order);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.event_partners'::regclass
      and conname = 'event_partners_tier_check'
  ) then
    alter table public.event_partners
      add constraint event_partners_tier_check
      check (tier in ('partner', 'featured_partner', 'official_partner'));
  end if;
end;
$$;

-- 4. Derived Future Times event-partner badge
create or replace function public.event_has_ft_service(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.ft_service_bookings
    where event_id = p_event_id
      and status in ('approved', 'active', 'completed')
  );
$$;

-- 5. Booking reminders
create table if not exists public.ft_service_reminders (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.ft_service_bookings(id) on delete cascade,
  remind_at timestamptz not null,
  kind text not null check (kind in ('7_day', '1_day', 'day_of')),
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique (booking_id, kind)
);

create index if not exists ft_reminders_pending_idx
  on public.ft_service_reminders(remind_at)
  where sent_at is null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_service_reminders'::regclass
      and conname = 'ft_service_reminders_kind_check'
  ) then
    alter table public.ft_service_reminders
      add constraint ft_service_reminders_kind_check
      check (kind in ('7_day', '1_day', 'day_of'));
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.ft_service_reminders'::regclass
      and conname = 'ft_service_reminders_booking_id_kind_key'
  ) then
    alter table public.ft_service_reminders
      add constraint ft_service_reminders_booking_id_kind_key
      unique (booking_id, kind);
  end if;
end;
$$;

-- 6. Shared updated_at trigger
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists ft_services_touch_updated_at
  on public.ft_services;
create trigger ft_services_touch_updated_at
  before update on public.ft_services
  for each row execute function public.touch_updated_at();

drop trigger if exists ft_service_bookings_touch_updated_at
  on public.ft_service_bookings;
create trigger ft_service_bookings_touch_updated_at
  before update on public.ft_service_bookings
  for each row execute function public.touch_updated_at();

-- 7. Row-level security
alter table public.ft_services enable row level security;
alter table public.ft_service_bookings enable row level security;
alter table public.event_partners enable row level security;
alter table public.ft_service_reminders enable row level security;

drop policy if exists "FT services are publicly readable"
  on public.ft_services;
create policy "FT services are publicly readable"
  on public.ft_services for select
  to anon, authenticated
  using (true);

drop policy if exists "Super admins manage FT services"
  on public.ft_services;
create policy "Super admins manage FT services"
  on public.ft_services for all
  to authenticated
  using (coalesce(public.is_super_admin(), false))
  with check (coalesce(public.is_super_admin(), false));

drop policy if exists "Organizers and admins read FT bookings"
  on public.ft_service_bookings;
create policy "Organizers and admins read FT bookings"
  on public.ft_service_bookings for select
  to authenticated
  using (
    organizer_id = auth.uid()
    or coalesce(public.is_super_admin(), false)
  );

drop policy if exists "Organizers request own FT bookings"
  on public.ft_service_bookings;
create policy "Organizers request own FT bookings"
  on public.ft_service_bookings for insert
  to authenticated
  with check (
    organizer_id = auth.uid()
    and status in ('draft', 'pending_payment')
    and exists (
      select 1
      from public.events e
      where e.id = event_id
        and e.organizer_id = auth.uid()
    )
  );

drop policy if exists "Organizers update pending FT bookings"
  on public.ft_service_bookings;
create policy "Organizers update pending FT bookings"
  on public.ft_service_bookings for update
  to authenticated
  using (
    organizer_id = auth.uid()
    and status in ('draft', 'pending_payment')
  )
  with check (
    organizer_id = auth.uid()
    and status in ('draft', 'pending_payment')
  );

drop policy if exists "Super admins update any FT booking"
  on public.ft_service_bookings;
create policy "Super admins update any FT booking"
  on public.ft_service_bookings for update
  to authenticated
  using (coalesce(public.is_super_admin(), false))
  with check (coalesce(public.is_super_admin(), false));

drop policy if exists "Super admins delete FT bookings"
  on public.ft_service_bookings;
create policy "Super admins delete FT bookings"
  on public.ft_service_bookings for delete
  to authenticated
  using (coalesce(public.is_super_admin(), false));

drop policy if exists "Event partners are publicly readable"
  on public.event_partners;
create policy "Event partners are publicly readable"
  on public.event_partners for select
  to anon, authenticated
  using (true);

drop policy if exists "Organizers manage partners on own events"
  on public.event_partners;
create policy "Organizers manage partners on own events"
  on public.event_partners for all
  to authenticated
  using (
    coalesce(public.is_super_admin(), false)
    or exists (
      select 1 from public.events e
      where e.id = event_id and e.organizer_id = auth.uid()
    )
  )
  with check (
    coalesce(public.is_super_admin(), false)
    or exists (
      select 1 from public.events e
      where e.id = event_id and e.organizer_id = auth.uid()
    )
  );

drop policy if exists "Organizers and admins read FT reminders"
  on public.ft_service_reminders;
create policy "Organizers and admins read FT reminders"
  on public.ft_service_reminders for select
  to authenticated
  using (
    coalesce(public.is_super_admin(), false)
    or exists (
      select 1
      from public.ft_service_bookings b
      where b.id = booking_id and b.organizer_id = auth.uid()
    )
  );

drop policy if exists "Service role manages FT reminders"
  on public.ft_service_reminders;
create policy "Service role manages FT reminders"
  on public.ft_service_reminders for all
  to service_role
  using (true)
  with check (true);

grant select on public.ft_services to anon, authenticated;
grant insert, update, delete on public.ft_services to authenticated;
grant select, insert, update, delete
  on public.ft_service_bookings to authenticated;
grant select on public.event_partners to anon, authenticated;
grant insert, update, delete on public.event_partners to authenticated;
grant select on public.ft_service_reminders to authenticated;
grant all on public.ft_service_reminders to service_role;

-- 8. Create a pending booking after validating ownership and request values.
create or replace function public.request_service_booking(
  p_service_id uuid,
  p_event_id uuid,
  p_quantity int,
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_service public.ft_services%rowtype;
  v_booking_id uuid;
  v_total numeric(10,2);
  v_deposit numeric(10,2);
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select *
    into v_service
    from public.ft_services
    where id = p_service_id and is_active = true;
  if not found then
    raise exception 'Service not available' using errcode = 'P0002';
  end if;

  if p_start_time is null or p_end_time is null
     or p_end_time <= p_start_time then
    raise exception 'End time must be after start time'
      using errcode = '22023';
  end if;
  if p_quantity is null or p_quantity <= 0
     or p_quantity > v_service.total_quantity then
    raise exception 'Invalid quantity' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.events
    where id = p_event_id and organizer_id = auth.uid()
  ) then
    raise exception 'You do not own this event' using errcode = '42501';
  end if;

  v_total := v_service.base_price * p_quantity;
  v_deposit := round(v_total * v_service.deposit_percent / 100.0, 2);

  insert into public.ft_service_bookings (
    service_id, event_id, organizer_id, quantity, start_time, end_time,
    total_price, deposit_amount, currency, status, notes
  ) values (
    p_service_id, p_event_id, auth.uid(), p_quantity, p_start_time, p_end_time,
    v_total, v_deposit, v_service.currency, 'pending_payment', p_notes
  )
  returning id into v_booking_id;

  return v_booking_id;
end;
$$;

-- 9. Report remaining inventory for a service and time range.
create or replace function public.check_service_availability(
  p_service_id uuid,
  p_start_time timestamptz,
  p_end_time timestamptz
)
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_total int;
  v_booked int;
begin
  if p_start_time is null or p_end_time is null
     or p_end_time <= p_start_time then
    raise exception 'End time must be after start time'
      using errcode = '22023';
  end if;

  select total_quantity
    into v_total
    from public.ft_services
    where id = p_service_id and is_active = true;
  if v_total is null then
    raise exception 'Service not found or inactive' using errcode = 'P0002';
  end if;

  select coalesce(sum(quantity), 0)
    into v_booked
    from public.ft_service_bookings
    where service_id = p_service_id
      and status in ('deposit_paid', 'pending_review', 'approved', 'active')
      and tstzrange(start_time, end_time, '[)')
          && tstzrange(p_start_time, p_end_time, '[)');

  return json_build_object(
    'total', v_total,
    'booked', v_booked,
    'available', greatest(v_total - v_booked, 0)
  );
end;
$$;

-- 10. Confirm a paid deposit and serialize inventory checks on the service row.
create or replace function public.confirm_service_booking(
  p_booking_id uuid,
  p_payment_transaction_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.ft_service_bookings%rowtype;
  v_booked int;
  v_total int;
  v_payment_exists boolean;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  select *
    into v_booking
    from public.ft_service_bookings
    where id = p_booking_id
    for update;
  if not found then
    raise exception 'Booking not found' using errcode = 'P0002';
  end if;
  if v_booking.organizer_id <> auth.uid() then
    raise exception 'Not your booking' using errcode = '42501';
  end if;
  if v_booking.status <> 'pending_payment' then
    raise exception 'Booking is not pending payment' using errcode = '22023';
  end if;

  select exists (
    select 1
    from public.payment_transactions
    where id = p_payment_transaction_id
      and user_id = auth.uid()
      and related_entity_id = p_booking_id::text
      and purpose = 'service'
      and status = 'paid'
  ) into v_payment_exists;
  if not coalesce(v_payment_exists, false) then
    raise exception 'A successful service deposit is required'
      using errcode = '22023';
  end if;

  select total_quantity
    into v_total
    from public.ft_services
    where id = v_booking.service_id
    for update;
  if v_total is null then
    raise exception 'Service not found' using errcode = 'P0002';
  end if;

  select coalesce(sum(quantity), 0)
    into v_booked
    from public.ft_service_bookings
    where service_id = v_booking.service_id
      and id <> p_booking_id
      and status in ('deposit_paid', 'pending_review', 'approved', 'active')
      and tstzrange(start_time, end_time, '[)')
          && tstzrange(v_booking.start_time, v_booking.end_time, '[)');

  if v_booked + v_booking.quantity > v_total then
    -- Returning NULL preserves the cancellation in this transaction. Raising
    -- an exception here would roll back the status update in PostgreSQL.
    update public.ft_service_bookings
      set status = 'cancelled',
          notes = concat_ws(
            E'\n',
            nullif(notes, ''),
            'Auto-cancelled: inventory conflict at deposit confirmation.'
          )
      where id = p_booking_id;
    return null;
  end if;

  update public.ft_service_bookings
    set status = 'pending_review',
        payment_transaction_id = p_payment_transaction_id
    where id = p_booking_id;

  insert into public.ft_service_reminders (booking_id, remind_at, kind)
  values
    (p_booking_id, v_booking.start_time - interval '7 days', '7_day'),
    (p_booking_id, v_booking.start_time - interval '1 day', '1_day'),
    (p_booking_id, v_booking.start_time, 'day_of')
  on conflict (booking_id, kind) do nothing;

  return p_booking_id;
end;
$$;

-- 11. Super-admin review of paid service requests.
create or replace function public.admin_review_service_booking(
  p_booking_id uuid,
  p_decision text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not coalesce(public.is_super_admin(), false) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  if p_decision not in ('approve', 'reject') then
    raise exception 'Invalid decision' using errcode = '22023';
  end if;

  if p_decision = 'approve' then
    update public.ft_service_bookings
      set status = 'approved',
          reviewed_by = auth.uid(),
          reviewed_at = now(),
          rejection_reason = null
      where id = p_booking_id and status = 'pending_review';
  else
    update public.ft_service_bookings
      set status = 'rejected',
          reviewed_by = auth.uid(),
          reviewed_at = now(),
          rejection_reason = p_reason
      where id = p_booking_id and status = 'pending_review';
  end if;

  if not found then
    raise exception 'Booking not in pending_review state'
      using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.event_has_ft_service(uuid) from public;
grant execute on function public.event_has_ft_service(uuid)
  to authenticated, anon;
revoke all on function public.request_service_booking(
  uuid, uuid, int, timestamptz, timestamptz, text
) from public, anon;
grant execute on function public.request_service_booking(
  uuid, uuid, int, timestamptz, timestamptz, text
) to authenticated;
revoke all on function public.check_service_availability(
  uuid, timestamptz, timestamptz
) from public;
grant execute on function public.check_service_availability(
  uuid, timestamptz, timestamptz
) to authenticated, anon;
revoke all on function public.confirm_service_booking(uuid, uuid)
  from public, anon;
grant execute on function public.confirm_service_booking(uuid, uuid)
  to authenticated;
revoke all on function public.admin_review_service_booking(uuid, text, text)
  from public, anon;
grant execute on function public.admin_review_service_booking(uuid, text, text)
  to authenticated;

-- 12. Keep booking changes available to realtime clients.
do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'ft_service_bookings'
  ) then
    alter publication supabase_realtime
      add table public.ft_service_bookings;
  end if;
end;
$$;

-- 13. Default catalog. Existing rows (including prices/images) are preserved.
insert into public.ft_services
  (name, category, base_price, currency, unit, deposit_percent, total_quantity,
   image_url, sort_order)
values
  ('Concert Main Stage (12m x 8m)', 'stages', 800, 'USD', 'day', 30, 1, null, 10),
  ('Club Stage (6m x 4m)', 'stages', 350, 'USD', 'day', 30, 2, null, 20),
  ('Stage Roof & Truss', 'stages', 200, 'USD', 'day', 30, 3, null, 30),
  ('Premium Line Array (B&W tier)', 'audio', 600, 'USD', 'event', 30, 2, null, 10),
  ('Club PA System', 'audio', 250, 'USD', 'event', 30, 3, null, 20),
  ('Wireless Mics (pair)', 'audio', 40, 'USD', 'day', 30, 8, null, 30),
  ('Moving Heads Rig (8x)', 'lighting', 300, 'USD', 'day', 30, 2, null, 10),
  ('Stage Wash Package', 'lighting', 180, 'USD', 'day', 30, 3, null, 20),
  ('Cabana Tent (3m x 3m)', 'tents', 60, 'USD', 'day', 30, 20, null, 10),
  ('Cabana Tent (5m x 5m)', 'tents', 120, 'USD', 'day', 30, 10, null, 20),
  ('Marquee 20m x 10m', 'tents', 500, 'USD', 'day', 30, 2, null, 30),
  ('Standard Catering (per 50 guests)', 'catering', 400, 'USD', 'event', 50, 5, null, 10),
  ('Premium Catering (per 50 guests)', 'catering', 800, 'USD', 'event', 50, 3, null, 20),
  ('Event Videography (2 cams)', 'videography', 350, 'USD', 'event', 40, 4, null, 10),
  ('Full Day Video + Edit', 'videography', 600, 'USD', 'event', 40, 2, null, 20),
  ('Event Photography (4 hrs)', 'photography', 250, 'USD', 'event', 40, 5, null, 10),
  ('Full Day Photography', 'photography', 450, 'USD', 'event', 40, 3, null, 20),
  ('Brand Mascot Appearance (1 hr)', 'mascots', 80, 'USD', 'event', 50, 6, null, 10),
  ('Full Day Mascot', 'mascots', 300, 'USD', 'event', 50, 3, null, 20),
  ('LED Billboard Screen (4m x 2m)', 'screens', 700, 'USD', 'day', 30, 2, null, 10),
  ('Stage LED Wall (8m x 4m)', 'screens', 1500, 'USD', 'day', 30, 1, null, 20),
  ('Projector + Screen', 'screens', 150, 'USD', 'day', 30, 4, null, 30),
  ('Round Table (8-seat)', 'furniture', 15, 'USD', 'day', 20, 50, null, 10),
  ('Chair', 'furniture', 3, 'USD', 'day', 20, 500, null, 20),
  ('Event Decor Package', 'decor', 250, 'USD', 'event', 40, 5, null, 10),
  ('Silent Generator 20kVa', 'power', 200, 'USD', 'day', 30, 3, null, 10),
  ('Silent Generator 60kVa', 'power', 500, 'USD', 'day', 30, 2, null, 20)
on conflict (name) do nothing;
