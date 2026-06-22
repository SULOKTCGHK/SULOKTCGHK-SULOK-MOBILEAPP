-- collection 售出記錄：標記已售出、記錄售價與售出日期（已實現盈虧）
alter table collection add column if not exists status         text default 'holding'; -- holding / sold
alter table collection add column if not exists sold_price_hkd numeric;
alter table collection add column if not exists sold_at        timestamptz;
