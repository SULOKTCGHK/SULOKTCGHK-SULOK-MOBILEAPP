

create table if not exists wishlist (
  id          uuid primary key default gen_random_uuid(),
  user_id     text not null,
  set_id      text,
  card_number text,
  keyword     text,
  max_price   int,
  created_at  timestamptz default now()
);

create index if not exists idx_wishlist_user on wishlist(user_id, created_at desc);

alter table wishlist enable row level security;
drop policy if exists "all_wishlist" on wishlist;
create policy "all_wishlist" on wishlist for all using (true) with check (true);
