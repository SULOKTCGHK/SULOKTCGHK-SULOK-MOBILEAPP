-- PSA Pop 緩存表
create table if not exists psa_pop_cache (
  spec_id    text primary key,
  card_name  text,
  set_name   text,
  pop_10     int  default 0,
  pop_9      int  default 0,
  pop_8      int  default 0,
  pop_7      int  default 0,
  pop_6      int  default 0,
  pop_5      int  default 0,
  pop_auth   int  default 0,  -- Authentic
  total      int  default 0,
  fetched_at timestamptz default now()
);

-- cached_cards 加 psa_spec_id 欄位（admin 填）
alter table cached_cards
  add column if not exists psa_spec_id text;
