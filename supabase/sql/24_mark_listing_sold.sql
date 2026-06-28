-- 接受出價後把掛售標記為已售（security definer：繞過 RLS）
-- offer.listingId 為文字，需轉 uuid
create or replace function mark_listing_sold(p_listing_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update listings
  set status = 'sold', is_active = false
  where id = p_listing_id::uuid;
$$;
