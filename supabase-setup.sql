-- Run this in Supabase Dashboard → SQL Editor → New Query → paste → Run
--
-- This REPLACES the earlier open-access setup. Each row is now owned by a
-- user, and only that user can see or change it. The anon key stays public
-- (it has to — the browser needs it), but on its own it grants nothing.

-- 1. Rebuild the table with an owner column.
--    Safe to drop: the old table never accepted a single write, because the
--    anon role was never granted table privileges.
drop table if exists protocol_kv;

create table protocol_kv (
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null,
  value      jsonb not null,
  updated_at timestamptz default now(),
  primary key (user_id, key)
);

-- 2. Enable Row Level Security
alter table protocol_kv enable row level security;

-- 3. Owner-only policies. auth.uid() is the id of the logged-in user;
--    it is null for anyone who is not signed in, so nothing matches.
create policy "Owner can read own rows"
  on protocol_kv for select
  using (auth.uid() = user_id);

create policy "Owner can insert own rows"
  on protocol_kv for insert
  with check (auth.uid() = user_id);

create policy "Owner can update own rows"
  on protocol_kv for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Owner can delete own rows"
  on protocol_kv for delete
  using (auth.uid() = user_id);

-- 4. Table privileges. RLS filters rows, but Postgres checks these FIRST —
--    without them every request fails with 42501 regardless of policy.
--    Only signed-in users get them; anon is explicitly given nothing.
grant select, insert, update, delete on public.protocol_kv to authenticated;
revoke all on public.protocol_kv from anon;
