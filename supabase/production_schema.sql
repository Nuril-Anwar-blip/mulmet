-- Skema produksi Bank Mandiri Mobile Banking.
-- Jalankan setelah mobile_banking_latest_database.sql atau sebagai migrasi tambahan.

create table if not exists public.notification (
  id text not null,
  userid text not null,
  title text not null,
  body text not null,
  category text not null default 'Umum',
  isread boolean not null default false,
  createdat timestamp without time zone not null default current_timestamp,
  constraint notification_pkey primary key (id),
  constraint notification_userid_fkey foreign key (userid) references public.user(id)
);

alter table public.account add column if not exists label text;

update public.account
set label = 'Tabungan ' || bankname
where label is null;

create index if not exists notification_userid_idx on public.notification(userid);
create index if not exists notification_createdat_idx on public.notification(createdat);

alter table if exists public.notification disable row level security;

grant select, insert, update, delete on table public.notification to anon, authenticated;

-- Contoh rekening tambahan untuk fitur ganti rekening.
insert into public.account (id, userid, accountnumber, balance, bankname, label)
select
  'ACC-PROD-NURIL-2',
  u.id,
  '1234567891',
  2500000,
  'Mandiri',
  'Tabungan Mandiri Plus'
from public.user u
where u.username = 'nuril'
on conflict (accountnumber) do update set
  label = excluded.label,
  balance = excluded.balance;
