-- Run this in Supabase Dashboard → SQL Editor → New Query → paste → Run
--
-- IMPORTANT: click into the editor and make sure NOTHING is highlighted
-- before hitting Run. If any text is selected, Supabase runs only the
-- selection, which silently applies half the script.
--
-- Safe to re-run as many times as needed.

-- 1. Rebuild the table with an owner column.
--    Dropping is safe: no write to this table has ever succeeded. Before auth
--    the anon role had no privileges (42501); after auth the app started
--    sending user_id, which the old table rejected (42703). It is empty.
drop table if exists public.protocol_kv cascade;

create table public.protocol_kv (
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null,
  value      jsonb not null,
  updated_at timestamptz default now(),
  primary key (user_id, key)
);

-- 2. Enable Row Level Security
alter table public.protocol_kv enable row level security;

-- 3. Owner-only policies. auth.uid() is the id of the logged-in user;
--    it is null for anyone not signed in, so nothing matches.
drop policy if exists "Owner can read own rows"   on public.protocol_kv;
drop policy if exists "Owner can insert own rows" on public.protocol_kv;
drop policy if exists "Owner can update own rows" on public.protocol_kv;
drop policy if exists "Owner can delete own rows" on public.protocol_kv;

create policy "Owner can read own rows"
  on public.protocol_kv for select
  using (auth.uid() = user_id);

create policy "Owner can insert own rows"
  on public.protocol_kv for insert
  with check (auth.uid() = user_id);

create policy "Owner can update own rows"
  on public.protocol_kv for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Owner can delete own rows"
  on public.protocol_kv for delete
  using (auth.uid() = user_id);

-- 4. Table privileges. RLS filters rows, but Postgres checks these FIRST —
--    without them every request fails with 42501 regardless of policy.
grant select, insert, update, delete on public.protocol_kv to authenticated;
revoke all on public.protocol_kv from anon;

-- 5. Force PostgREST to pick up the new shape immediately instead of
--    serving a stale schema cache.
notify pgrst, 'reload schema';

-- 6. Verify. This should return exactly four rows:
--    user_id | key | value | updated_at
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'protocol_kv'
order by ordinal_position;
