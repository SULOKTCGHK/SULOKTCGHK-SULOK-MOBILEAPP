-- Admin 系統：admins 表 + 讓 admin 能從 app 管理 card_shops / announcements
-- 第一個 admin 請手動在 Table Editor 加：insert into admins(user_id) values ('你的帳號uid');

create table if not exists admins (
  user_id    text primary key,
  created_at timestamptz default now()
);
alter table admins enable row level security;
drop policy if exists "admins_read_self" on admins;
-- 登入者可查自己是不是 admin
create policy "admins_read_self" on admins for select
  using (user_id::text = (select auth.uid())::text);

-- 共用：目前登入者是否為 admin
-- (在各表政策內嵌 exists 查詢)

-- card_shops：admin 可增刪改（讀已公開）
drop policy if exists "card_shops_admin_write" on card_shops;
create policy "card_shops_admin_write" on card_shops for all
  using (exists (select 1 from admins a where a.user_id::text = (select auth.uid())::text))
  with check (exists (select 1 from admins a where a.user_id::text = (select auth.uid())::text));

-- announcements：admin 可增刪改（附加政策，不影響既有讀取）
drop policy if exists "announcements_admin_write" on announcements;
create policy "announcements_admin_write" on announcements for all
  using (exists (select 1 from admins a where a.user_id::text = (select auth.uid())::text))
  with check (exists (select 1 from admins a where a.user_id::text = (select auth.uid())::text));
