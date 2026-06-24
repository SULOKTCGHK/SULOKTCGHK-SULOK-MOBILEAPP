alter table listings
  add column if not exists meetup_locations text[] default '{}';
