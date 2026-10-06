create table if not exists public.event_likes (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index if not exists event_likes_event_idx
  on public.event_likes(event_id);
create index if not exists event_likes_user_idx
  on public.event_likes(user_id);

alter table public.event_likes enable row level security;
grant select on public.event_likes to anon, authenticated;
grant insert, delete on public.event_likes to authenticated;

drop policy if exists "Anyone can count likes" on public.event_likes;
create policy "Anyone can count likes"
  on public.event_likes for select using (true);

drop policy if exists "Users like as themselves" on public.event_likes;
create policy "Users like as themselves"
  on public.event_likes for insert with check (auth.uid() = user_id);

drop policy if exists "Users unlike their own" on public.event_likes;
create policy "Users unlike their own"
  on public.event_likes for delete using (auth.uid() = user_id);

create or replace function public.get_event_like_counts(p_event_ids uuid[])
returns table (event_id uuid, like_count bigint)
language sql stable security definer set search_path = public
as $$
  select event_id, count(*)::bigint
  from public.event_likes
  where event_id = any(p_event_ids)
  group by event_id;
$$;

grant execute on function public.get_event_like_counts(uuid[]) to authenticated, anon;
