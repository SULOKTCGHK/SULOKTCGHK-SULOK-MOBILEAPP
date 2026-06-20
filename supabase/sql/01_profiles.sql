

create table if not exists profiles (
  id           text primary key,
  username     text unique,
  display_name text,
  avatar_emoji text default '🎴',
  bio          text default '',
  ig_handle    text default '',
  created_at   timestamptz default now(),
  updated_at   timestamptz
);

create index if not exists idx_profiles_username on profiles(username);

alter table profiles enable row level security;
drop policy if exists "all_profiles" on profiles;
create policy "all_profiles" on profiles for all using (true) with check (true);
