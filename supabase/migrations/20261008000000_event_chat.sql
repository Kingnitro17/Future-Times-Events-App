create table if not exists public.event_messages (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.events(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete cascade,
  kind text not null default 'text'
    check (kind in ('text','image','sticker')),
  body text,
  media_url text,
  sticker_id text,
  created_at timestamptz not null default now()
);

create index if not exists event_messages_event_idx
on public.event_messages(event_id, created_at desc);

create table if not exists public.event_message_reactions (
  message_id uuid references public.event_messages(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  emoji text not null,
  created_at timestamptz default now(),
  primary key (message_id, user_id, emoji)
);

alter table public.event_messages enable row level security;
alter table public.event_message_reactions enable row level security;

create or replace function public.user_has_ticket_for_event(p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
select exists (
  select 1
  from public.tickets t
  join public.ticket_types tt on tt.id = t.ticket_type_id
  where tt.event_id = p_event_id and t.user_id = auth.uid()
    and t.status in ('active','checked_in')
);
$$;

grant execute on function public.user_has_ticket_for_event(uuid) to authenticated;

drop policy if exists "Ticket holders read messages" on public.event_messages;
create policy "Ticket holders read messages" on public.event_messages
for select to authenticated
using (
  public.user_has_ticket_for_event(event_id)
  or exists (select 1 from public.events e where e.id = event_messages.event_id and e.organizer_id = auth.uid())
  or public.is_super_admin()
);

drop policy if exists "Ticket holders send messages" on public.event_messages;
create policy "Ticket holders send messages" on public.event_messages
for insert to authenticated
with check (
  auth.uid() = sender_id
  and (
    public.user_has_ticket_for_event(event_id)
    or exists (select 1 from public.events e where e.id = event_messages.event_id and e.organizer_id = auth.uid())
  )
);

drop policy if exists "Senders delete own messages" on public.event_messages;
create policy "Senders delete own messages" on public.event_messages
for delete to authenticated
using (auth.uid() = sender_id or public.is_super_admin());

drop policy if exists "Ticket holders react" on public.event_message_reactions;
create policy "Ticket holders react" on public.event_message_reactions
for all to authenticated
using (
  auth.uid() = user_id
  and exists (
    select 1
    from public.event_messages m
    where m.id = event_message_reactions.message_id
      and public.user_has_ticket_for_event(m.event_id)
  )
)
with check (auth.uid() = user_id);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and tablename = 'event_messages'
  ) then
    alter publication supabase_realtime add table public.event_messages;
  end if;
end $$;

insert into storage.buckets (id, name, public)
values ('event_chat', 'event_chat', true)
on conflict (id) do nothing;

drop policy if exists "Authed users upload chat images" on storage.objects;
create policy "Authed users upload chat images" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'event_chat'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Authed users update own chat images" on storage.objects;
create policy "Authed users update own chat images" on storage.objects
for update to authenticated
using (
  bucket_id = 'event_chat'
  and (storage.foldername(name))[1] = auth.uid()::text
);
