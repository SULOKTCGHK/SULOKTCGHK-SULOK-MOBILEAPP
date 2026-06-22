-- ============================================================
-- 18_rls_policies.sql — 用戶資料表 RLS（登入者只能改自己的）
-- 原本是 using(true) with check(true)（人人可改任何資料），這裡收緊。
-- 比對鍵：(select auth.uid())::text = <owner 欄位>
--   已登入 → auth.uid() = 帳號 uid；匿名 → null（寫入一律被拒，符合預期）
--
-- 注意：cached_sets / cached_cards / snkrdunk_prices 不在此檔（catalog/快取，
--       仍由抓取腳本與 app 用 anon 寫入，維持開放，之後再單獨硬化）。
--
-- 還原（萬一出事，把某表改回全開）：
--   drop policy if exists "<t>_select" on <t>; ...（四個）
--   create policy "<t>_all" on <t> for all using(true) with check(true);
-- ============================================================

-- 先把這些表既有的所有 policy 清掉
do $$
declare r record;
declare t text;
declare tbls text[] := array['profiles','listings','offers','conversations',
  'messages','follows','collection','transactions','notifications','reviews','wishlist'];
begin
  foreach t in array tbls loop
    execute format('alter table %I enable row level security', t);
    for r in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy %I on %I', r.policyname, t);
    end loop;
  end loop;
end $$;

-- 共用：目前登入者 uid（文字）
-- 用 (select auth.uid())::text 比對 text 欄位

-- profiles：公開讀（顯示賣家名），只能改自己
create policy "profiles_select" on profiles for select using (true);
create policy "profiles_insert" on profiles for insert with check (id = (select auth.uid())::text);
create policy "profiles_update" on profiles for update using (id = (select auth.uid())::text) with check (id = (select auth.uid())::text);

-- listings：公開讀（瀏覽掛售），只有賣家本人可寫
create policy "listings_select" on listings for select using (true);
create policy "listings_insert" on listings for insert with check (seller_id = (select auth.uid())::text);
create policy "listings_update" on listings for update using (seller_id = (select auth.uid())::text) with check (seller_id = (select auth.uid())::text);
create policy "listings_delete" on listings for delete using (seller_id = (select auth.uid())::text);

-- offers：買賣雙方可讀；買家建立；雙方可更新（接受/拒絕/取消）
create policy "offers_select" on offers for select using (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);
create policy "offers_insert" on offers for insert with check (buyer_id = (select auth.uid())::text);
create policy "offers_update" on offers for update using (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);
create policy "offers_delete" on offers for delete using (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);

-- conversations：參與者可讀寫
create policy "conv_select" on conversations for select using (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);
create policy "conv_insert" on conversations for insert with check (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);
create policy "conv_update" on conversations for update using (buyer_id = (select auth.uid())::text or seller_id = (select auth.uid())::text);

-- messages：屬於自己參與的對話才可讀；只能以自己身分送
create policy "msg_select" on messages for select using (
  exists (select 1 from conversations c where c.id = messages.conversation_id
          and (c.buyer_id = (select auth.uid())::text or c.seller_id = (select auth.uid())::text)));
create policy "msg_insert" on messages for insert with check (sender_id = (select auth.uid())::text);

-- follows：公開讀（粉絲數），只有本人可追蹤/取消
create policy "follows_select" on follows for select using (true);
create policy "follows_insert" on follows for insert with check (follower_id = (select auth.uid())::text);
create policy "follows_delete" on follows for delete using (follower_id = (select auth.uid())::text);

-- collection：私人，只有本人
create policy "collection_select" on collection for select using (user_id = (select auth.uid())::text);
create policy "collection_insert" on collection for insert with check (user_id = (select auth.uid())::text);
create policy "collection_update" on collection for update using (user_id = (select auth.uid())::text) with check (user_id = (select auth.uid())::text);
create policy "collection_delete" on collection for delete using (user_id = (select auth.uid())::text);

-- transactions：私人，只有本人
create policy "tx_select" on transactions for select using (user_id = (select auth.uid())::text);
create policy "tx_insert" on transactions for insert with check (user_id = (select auth.uid())::text);
create policy "tx_update" on transactions for update using (user_id = (select auth.uid())::text) with check (user_id = (select auth.uid())::text);
create policy "tx_delete" on transactions for delete using (user_id = (select auth.uid())::text);

-- notifications：只看/改自己的；建立可給別人（系統通知），需登入
create policy "notif_select" on notifications for select using (user_id = (select auth.uid())::text);
create policy "notif_insert" on notifications for insert with check ((select auth.uid()) is not null);
create policy "notif_update" on notifications for update using (user_id = (select auth.uid())::text);
create policy "notif_delete" on notifications for delete using (user_id = (select auth.uid())::text);

-- reviews：公開讀（賣家頁顯示），只有評價者本人可寫
create policy "reviews_select" on reviews for select using (true);
create policy "reviews_insert" on reviews for insert with check (reviewer_id = (select auth.uid())::text);
create policy "reviews_update" on reviews for update using (reviewer_id = (select auth.uid())::text) with check (reviewer_id = (select auth.uid())::text);
create policy "reviews_delete" on reviews for delete using (reviewer_id = (select auth.uid())::text);

-- wishlist：私人，只有本人
create policy "wishlist_select" on wishlist for select using (user_id = (select auth.uid())::text);
create policy "wishlist_insert" on wishlist for insert with check (user_id = (select auth.uid())::text);
create policy "wishlist_update" on wishlist for update using (user_id = (select auth.uid())::text) with check (user_id = (select auth.uid())::text);
create policy "wishlist_delete" on wishlist for delete using (user_id = (select auth.uid())::text);
