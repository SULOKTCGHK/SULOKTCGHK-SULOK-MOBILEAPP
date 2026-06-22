-- cached_sets：圖鑑系列快取（來源 TCGdex）

create table if not exists cached_sets (
  id           text primary key,
  name         text,
  series       text,
  series_id    text,
  release_date text,
  symbol_image text,
  logo_image   text,
  total        int default 0,
  language     text default 'ja',   -- ja = 日版, en = 英版
  cached_at    bigint
);

create index if not exists idx_cached_sets_release on cached_sets(release_date desc);
create index if not exists idx_cached_sets_lang on cached_sets(language);

alter table cached_sets enable row level security;
drop policy if exists "all_cached_sets" on cached_sets;
create policy "all_cached_sets" on cached_sets for all using (true) with check (true);
