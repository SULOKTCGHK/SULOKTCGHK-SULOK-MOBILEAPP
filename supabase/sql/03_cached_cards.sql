-- cached_cards：圖鑑單卡快取（TCGdex / JustTCG PROMO，set_id 如 S-P、SM-P）

create table if not exists cached_cards (
  id                  text primary key,
  name                text,
  image_small         text,
  image_large         text,
  rarity              text,
  set_name            text,
  set_id              text,
  number              text,
  supertype           text,
  types               text,
  estimated_price_ntd int default 0,
  cached_at           bigint
);

create index if not exists idx_cached_cards_set on cached_cards(set_id, number);

alter table cached_cards enable row level security;
drop policy if exists "all_cached_cards" on cached_cards;
create policy "all_cached_cards" on cached_cards for all using (true) with check (true);
