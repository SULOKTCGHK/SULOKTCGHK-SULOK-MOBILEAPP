-- conversations：聊天對話（買家 × 賣家 × 商品）

create table if not exists conversations (
  id         uuid primary key default gen_random_uuid(),
  buyer_id   text not null,
  seller_id  text not null,
  card_id    text default '',
  card_name  text default '',
  card_price int default 0,
  created_at timestamptz default now()
);

create index if not exists idx_conv_buyer on conversations(buyer_id);
create index if not exists idx_conv_seller on conversations(seller_id);

alter table conversations enable row level security;
drop policy if exists "all_conversations" on conversations;
create policy "all_conversations" on conversations for all using (true) with check (true);
