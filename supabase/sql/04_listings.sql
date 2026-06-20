-- listings：掛售商品

create table if not exists listings (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  grade         text,
  card_type     text default 'normal',
  price         int not null,
  condition     text,
  listing_type  text default 'fixedPrice',  -- fixedPrice / auction
  description   text default '',
  image_urls    text[] default '{}',
  seller_id     text not null,
  seller_name   text,
  seller_rating numeric default 5.0,
  seller_sales  int default 0,
  bids          int default 0,
  is_active     boolean default true,
  status        text,                        -- null / sold
  set_id        text,
  card_number   text,
  created_at    timestamptz default now()
);

create index if not exists idx_listings_active on listings(is_active, created_at desc);
create index if not exists idx_listings_seller on listings(seller_id, created_at desc);
create index if not exists idx_listings_set on listings(set_id);

alter table listings enable row level security;
drop policy if exists "all_listings" on listings;
create policy "all_listings" on listings for all using (true) with check (true);
