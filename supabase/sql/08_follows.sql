-- follows：追蹤關係（follower 追蹤 seller）

create table if not exists follows (
  follower_id text not null,
  seller_id   text not null,
  created_at  timestamptz default now(),
  primary key (follower_id, seller_id)
);

create index if not exists idx_follows_seller on follows(seller_id);

alter table follows enable row level security;
drop policy if exists "all_follows" on follows;
create policy "all_follows" on follows for all using (true) with check (true);
