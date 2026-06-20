-- messages：聊天訊息（需 Realtime 即時更新）

create table if not exists messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  sender_id       text not null,
  content         text not null,
  created_at      timestamptz default now()
);

create index if not exists idx_messages_conv on messages(conversation_id, created_at);

alter table messages enable row level security;
drop policy if exists "all_messages" on messages;
create policy "all_messages" on messages for all using (true) with check (true);

-- 即時訊息
alter publication supabase_realtime add table messages;
