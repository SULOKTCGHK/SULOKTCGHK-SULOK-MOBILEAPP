-- offers：出價

create table if not exists offers (
  id         uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listings(id) on delete cascade,
  seller_id  text not null,
  buyer_id   text not null,
  buyer_name text,
  amount     int not null,
  status     text default 'pending',  -- pending / accepted / rejected
  created_at timestamptz default now()
);

create index if not exists idx_offers_listing on offers(listing_id, created_at desc);
create index if not exists idx_offers_seller on offers(seller_id, status);
create index if not exists idx_offers_buyer on offers(buyer_id);

alter table offers enable row level security;
drop policy if exists "all_offers" on offers;
create policy "all_offers" on offers for all using (true) with check (true);
