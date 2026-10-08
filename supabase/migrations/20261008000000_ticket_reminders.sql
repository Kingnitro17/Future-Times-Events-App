create table if not exists public.ticket_reminders (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references public.tickets(id) on delete cascade,
  remind_at timestamptz not null,
  kind text not null check (kind in ('event_week', 'event_day', 'tickets_running_out')),
  sent_at timestamptz,
  created_at timestamptz default now(),
  unique (ticket_id, kind)
);

create index if not exists ticket_reminders_pending_idx
on public.ticket_reminders(remind_at) where sent_at is null;

alter table public.ticket_reminders enable row level security;

drop policy if exists "Organizers see reminders for their events" on public.ticket_reminders;
create policy "Organizers see reminders for their events"
on public.ticket_reminders for select
to authenticated
using (
  exists (
    select 1
    from public.tickets t
    join public.ticket_types tt on tt.id = t.ticket_type_id
    join public.events e on e.id = tt.event_id
    where t.id = ticket_reminders.ticket_id and e.organizer_id = auth.uid()
  )
  or public.is_super_admin()
);

create or replace function public.schedule_ticket_reminders()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_start timestamptz;
begin
  select e.start_time into v_event_start
  from public.ticket_types tt
  join public.events e on e.id = tt.event_id
  where tt.id = new.ticket_type_id;

  if v_event_start is null then
    return new;
  end if;

  insert into public.ticket_reminders (ticket_id, remind_at, kind)
  values
    (new.id, v_event_start - interval '7 days', 'event_week'),
    (new.id, v_event_start - interval '1 day', 'event_day')
  on conflict (ticket_id, kind) do nothing;

  return new;
end;
$$;

drop trigger if exists tickets_schedule_reminders on public.tickets;
create trigger tickets_schedule_reminders
after insert on public.tickets
for each row
execute function public.schedule_ticket_reminders();

create or replace function public.process_ticket_reminders(p_limit int default 50)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_count int := 0;
begin
  for r in
    select tr.id, tr.ticket_id, tr.kind, t.user_id, e.title as event_title, e.start_time
    from public.ticket_reminders tr
    join public.tickets t on t.id = tr.ticket_id
    join public.ticket_types tt on tt.id = t.ticket_type_id
    join public.events e on e.id = tt.event_id
    where tr.sent_at is null and tr.remind_at <= now()
    order by tr.remind_at
    limit p_limit
  loop
    insert into public.notifications (user_id, kind, title, body, payload)
    values (
      r.user_id,
      'ticket_reminder',
      case r.kind
        when 'event_week' then 'Your event is next week'
        when 'event_day' then 'Your event is tomorrow'
        else 'Reminder'
      end,
      r.event_title || ' — ' || case r.kind
        when 'event_week' then 'starts in 7 days'
        when 'event_day' then 'starts tomorrow'
        else 'update'
      end,
      jsonb_build_object(
        'event_id', (select tt.event_id from public.ticket_types tt where tt.id = (select ticket_type_id from public.tickets where id = r.ticket_id))
      )
    );

    update public.ticket_reminders
    set sent_at = now()
    where id = r.id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

grant execute on function public.process_ticket_reminders(int) to authenticated;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  kind text not null,
  title text not null,
  body text,
  payload jsonb,
  read_at timestamptz,
  created_at timestamptz default now()
);

create index if not exists notifications_user_idx
on public.notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "Users see own notifications" on public.notifications;
create policy "Users see own notifications"
on public.notifications for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.schedule_low_stock_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_available int;
  v_organizer_id uuid;
begin
  if new.quantity_available is null then
    return new;
  end if;

  if new.quantity_total is not null and new.quantity_total > 0 then
    v_total := new.quantity_total;
    v_available := coalesce(new.quantity_available, 0);

    if (v_available::numeric / v_total::numeric) < 0.2 then
      select e.organizer_id into v_organizer_id
      from public.events e
      where e.id = new.event_id;

      if v_organizer_id is not null then
        insert into public.notifications (user_id, kind, title, body, payload)
        values (
          v_organizer_id,
          'low_stock',
          'Ticket stock is running low',
          'One of your ticket types is now below 20% inventory remaining.',
          jsonb_build_object('event_id', new.event_id, 'ticket_type_id', new.id)
        );
      end if;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists ticket_types_low_stock_notifications on public.ticket_types;
create trigger ticket_types_low_stock_notifications
after update of quantity_available on public.ticket_types
for each row
execute function public.schedule_low_stock_notifications();
