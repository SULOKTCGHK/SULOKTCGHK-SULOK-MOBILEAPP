-- 卡店加大區分類（香港島 / 九龍 / 新界 / 離島）
alter table card_shops add column if not exists region text;
