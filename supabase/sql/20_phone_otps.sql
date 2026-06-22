-- 電話 OTP 暫存（WhatsApp 自管驗證碼）。只由 whatsapp-verify Edge Function(service role) 存取。
create table if not exists phone_otps (
  user_id    text primary key,
  phone      text not null,
  code       text not null,
  expires_at timestamptz not null,
  created_at timestamptz default now()
);
alter table phone_otps enable row level security;
-- 不建任何 policy：client（anon/authenticated）無法讀寫；service role 會繞過 RLS。
