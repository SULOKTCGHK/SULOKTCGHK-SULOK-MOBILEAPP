-- snkrdunk_prices：SNKRDUNK 日本市場成交價快取（每張卡一筆，隔日重查）
-- payload 存 edge function 回傳的完整 JSON（含 psa10/psa9/raw 或 matched:false）

create table if not exists snkrdunk_prices (
  card_id    text primary key,
  payload    jsonb,
  fetched_at timestamptz default now()
);

alter table snkrdunk_prices enable row level security;
drop policy if exists "all_snkr" on snkrdunk_prices;
create policy "all_snkr" on snkrdunk_prices for all using (true) with check (true);
