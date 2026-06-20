-- reviews：交易評價（每筆交易/商品一位買家只能評一次）

create table if not exists reviews (
  id            uuid primary key default gen_random_uuid(),
  seller_id     text not null,
  reviewer_id   text not null,
  reviewer_name text,
  listing_id    text,
  rating        int not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz default now(),
  unique (reviewer_id, listing_id)
);

create index if not exists idx_reviews_seller on reviews(seller_id, created_at desc);

alter table reviews enable row level security;
drop policy if exists "all_reviews" on reviews;
create policy "all_reviews" on reviews for all using (true) with check (true);
