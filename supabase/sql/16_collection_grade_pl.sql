-- collection 升級：支援分級收藏 + 成本價/市價（盈虧計算）
-- grade: RAW / PSA10 / PSA9 ...；cost_hkd: 用戶成本價(港幣)；market_jpy: SNKRDUNK 當前市價快照(日圓)

alter table collection add column if not exists grade      text    default 'RAW';
alter table collection add column if not exists cost_hkd   numeric default 0;
alter table collection add column if not exists market_jpy int     default 0;

-- 同一張卡的不同分級可分開收藏
alter table collection drop constraint if exists collection_user_id_card_id_key;
alter table collection drop constraint if exists collection_user_card_grade_key;
alter table collection add  constraint collection_user_card_grade_key unique (user_id, card_id, grade);
