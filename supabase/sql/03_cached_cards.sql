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
  variant             text,                -- 花紋/球種變體，如 "Poke Ball Pattern"（取自卡名括號）
  language            text default 'ja',   -- ja = 日版, en = 英版
  estimated_price_ntd int default 0,
  cached_at           bigint
);

create index if not exists idx_cached_cards_set on cached_cards(set_id, number);
create index if not exists idx_cached_cards_lang on cached_cards(language, set_id);

alter table cached_cards enable row level security;
drop policy if exists "all_cached_cards" on cached_cards;
create policy "all_cached_cards" on cached_cards for all using (true) with check (true);
