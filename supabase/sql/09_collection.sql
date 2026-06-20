-- collection：個人收藏

create table if not exists collection (
  id                  uuid primary key default gen_random_uuid(),
  user_id             text not null,
  card_id             text not null,
  name                text,
  image_small         text,
  image_large         text,
  rarity              text,
  set_name            text,
  set_id              text,
  number              text,
  estimated_price_ntd int default 0,
  added_at            timestamptz default now(),
  unique (user_id, card_id)
);

create index if not exists idx_collection_user on collection(user_id, added_at desc);

alter table collection enable row level security;
drop policy if exists "all_collection" on collection;
create policy "all_collection" on collection for all using (true) with check (true);
