-- notifications：站內通知（鈴鐺，需 Realtime 即時更新）
-- type: offer_received / offer_accepted / offer_rejected / message / wishlist_match / review_received

create table if not exists notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    text not null,
  type       text not null,
  title      text not null,
  body       text,
  listing_id text,
  is_read    boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_notif_user on notifications(user_id, created_at desc);
create index if not exists idx_notif_unread on notifications(user_id, is_read);

alter table notifications enable row level security;
drop policy if exists "all_notif" on notifications;
create policy "all_notif" on notifications for all using (true) with check (true);

-- 讓鈴鐺未讀徽章即時更新
alter publication supabase_realtime add table notifications;
