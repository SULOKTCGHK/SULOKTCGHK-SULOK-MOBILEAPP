-- transactions：成交紀錄（用戶手動輸入，用於圖鑑卡片行情統計）

create table if not exists transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  card_id    text not null,
  card_name  text,
  grade      text default 'Raw',
  price_ntd  int not null,
  buyer      text,
  date       text,                     -- 顯示用日期字串 YYYY/MM/DD
  created_at timestamptz default now()
);

create index if not exists idx_tx_user_card on transactions(user_id, card_id, date desc);

alter table transactions enable row level security;
drop policy if exists "all_transactions" on transactions;
create policy "all_transactions" on transactions for all using (true) with check (true);
