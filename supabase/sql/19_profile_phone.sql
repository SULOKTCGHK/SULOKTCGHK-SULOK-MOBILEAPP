-- WhatsApp 電話認證：profiles 加電話與認證狀態
alter table profiles add column if not exists phone          text;
alter table profiles add column if not exists phone_verified boolean default false;

-- phone_verified 由 whatsapp-verify Edge Function 以 service role 設定（防 client 竄改）。
-- profiles 的 RLS：UPDATE 限本人（見 18_rls_policies.sql）；service role 會繞過 RLS，
-- 故只有後端（驗證碼通過後）能把 phone_verified 設為 true。
