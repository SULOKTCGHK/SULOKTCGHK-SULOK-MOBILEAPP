-- card_shops：實體卡鋪（附近卡鋪功能）。admin 維護，公開讀。
create table if not exists card_shops (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  address     text,
  district    text,                 -- 地區，如 旺角 / 觀塘
  lat         double precision not null,
  lng         double precision not null,
  phone       text,
  ig_handle   text,
  hours       text,                 -- 營業時間（自由文字）
  note        text,
  is_active   boolean default true,
  created_at  timestamptz default now()
);
create index if not exists idx_card_shops_active on card_shops(is_active);

alter table card_shops enable row level security;
drop policy if exists "card_shops_read" on card_shops;
create policy "card_shops_read" on card_shops for select using (true);
-- 寫入由 admin 經 Supabase 後台/service role；不開放 client 寫。

-- 範例（之後可在後台 Table Editor 加更多）：
-- insert into card_shops (name, address, district, lat, lng, phone) values
--   ('範例卡鋪', '旺角彌敦道 XXX 號', '旺角', 22.3193, 114.1694, '+85212345678');
