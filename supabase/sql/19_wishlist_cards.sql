-- 願望清單改為「具體卡片清單」(bucket list)
-- 從「條件式提醒」改為「收藏想要的具體卡片」

-- 清掉舊的條件式提醒資料（改為卡片清單）
delete from wishlist;

-- 新增卡片欄位
alter table wishlist add column if not exists card_id   text;
alter table wishlist add column if not exists card_name text;
alter table wishlist add column if not exists image_url text;
alter table wishlist add column if not exists set_name  text;

-- 每位用戶每張卡只存一筆
create unique index if not exists wishlist_user_card_uniq on wishlist(user_id, card_id);
