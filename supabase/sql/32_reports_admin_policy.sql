-- 讓 admin（admins 表內的 user）能查看與處理全部檢舉。
-- 需先跑過 31_reports_blocks.sql 及已有 admins 表。

drop policy if exists reports_admin_select on reports;
create policy reports_admin_select on reports
  for select using (
    exists (select 1 from admins where admins.user_id = auth.uid())
  );

drop policy if exists reports_admin_update on reports;
create policy reports_admin_update on reports
  for update using (
    exists (select 1 from admins where admins.user_id = auth.uid())
  ) with check (
    exists (select 1 from admins where admins.user_id = auth.uid())
  );
