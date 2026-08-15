-- Run this in Supabase Dashboard → SQL Editor → New Query → paste → Run

-- 1. Create the key-value table for protocol state
create table if not exists protocol_kv (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz default now()
);

-- 2. Enable Row Level Security
alter table protocol_kv enable row level security;

-- 3. Allow the anon key to read and write (single-user app)
create policy "Allow anon full access"
  on protocol_kv
  for all
  using (true)
  with check (true);
