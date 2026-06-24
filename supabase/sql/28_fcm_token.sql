alter table profiles
  add column if not exists fcm_token text,
  add column if not exists fcm_updated_at timestamptz;
