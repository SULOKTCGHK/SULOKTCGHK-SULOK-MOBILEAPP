-- 卡店記錄 Google Place ID（自動匯入用，避免重複）
alter table card_shops add column if not exists google_place_id text;
create unique index if not exists card_shops_gplace_uniq on card_shops(google_place_id);
