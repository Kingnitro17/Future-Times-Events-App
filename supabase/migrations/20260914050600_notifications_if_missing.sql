/*
  Notifications are already consumed by the Flutter client. Create the table
  only for environments where the existing notifications table is absent.
*/
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  type text,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

drop policy if exists "Users can view their own notifications"
  on public.notifications;
create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "Users can update their own notifications"
  on public.notifications;
create policy "Users can update their own notifications"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);
