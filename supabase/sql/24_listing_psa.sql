alter table listings
  add column if not exists psa_cert    text,
  add column if not exists psa_spec_id text;
