-- 檢舉 (reports) 與 封鎖 (blocks)。App Store UGC 規定的必要功能。

-- ── 檢舉 ──────────────────────────────────────────────────────────────────
create table if not exists reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null,   -- 'listing' | 'user' | 'message' | 'review'
  target_id   text not null,
  reason      text not null,   -- 檢舉原因代碼
  details     text,            -- 補充說明（選填）
  status      text not null default 'pending', -- pending | reviewed | actioned | dismissed
  created_at  timestamptz not null default now()
);

alter table reports enable row level security;

-- 登入用戶可提交自己的檢舉
drop policy if exists reports_insert on reports;
create policy reports_insert on reports
  for insert with check (auth.uid() = reporter_id);

-- 檢舉者可查看自己提交的檢舉
drop policy if exists reports_select_own on reports;
create policy reports_select_own on reports
  for select using (auth.uid() = reporter_id);

create index if not exists reports_target_idx on reports (target_type, target_id);
create index if not exists reports_status_idx on reports (status);

-- ── 封鎖 ──────────────────────────────────────────────────────────────────
create table if not exists blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

alter table blocks enable row level security;

-- 用戶只能管理自己的封鎖清單
drop policy if exists blocks_manage_own on blocks;
create policy blocks_manage_own on blocks
  for all using (auth.uid() = blocker_id) with check (auth.uid() = blocker_id);

create index if not exists blocks_blocker_idx on blocks (blocker_id);
