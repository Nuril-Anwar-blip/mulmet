-- Jalankan file ini di Supabase SQL Editor untuk database yang sudah terlanjur
-- punya tabel ganda: User/Account/Transaction/LoginLog/Favorite dan
-- user/account/transaction/loginlog/favorite.
--
-- Tabel yang dipakai Flutter adalah lowercase:
-- user, account, transaction, loginlog, favorite.

-- 1) Hapus tabel uppercase/camelCase yang tidak dipakai Flutter.
-- Jangan ubah menjadi public.User tanpa tanda kutip, karena itu bisa mengarah
-- ke tabel lowercase di PostgreSQL.
drop table if exists public."Transaction" cascade;
drop table if exists public."Favorite" cascade;
drop table if exists public."LoginLog" cascade;
drop table if exists public."Account" cascade;
drop table if exists public."User" cascade;

-- 2) Pastikan tabel lowercase yang dipakai Flutter tersedia.
create table if not exists public.user (
  id text not null,
  username text not null unique,
  password text not null,
  email text not null unique,
  fullname text not null,
  createdat timestamp without time zone not null default current_timestamp,
  updatedat timestamp without time zone not null default current_timestamp,
  constraint user_pkey primary key (id)
);

create table if not exists public.account (
  id text not null,
  userid text not null,
  accountnumber text not null unique,
  balance double precision not null default 0,
  bankname text not null default 'Mandiri',
  constraint account_pkey primary key (id),
  constraint account_userid_fkey foreign key (userid) references public.user(id)
);

create table if not exists public.transaction (
  id text not null,
  senderaccountid text not null,
  receiveraccountid text not null,
  amount double precision not null,
  fee double precision not null default 0.0,
  note text,
  status text not null default 'SUCCESS',
  referencenumber text not null unique,
  createdat timestamp without time zone not null default current_timestamp,
  constraint transaction_pkey primary key (id),
  constraint transaction_senderaccountid_fkey foreign key (senderaccountid) references public.account(id),
  constraint transaction_receiveraccountid_fkey foreign key (receiveraccountid) references public.account(id)
);

create table if not exists public.loginlog (
  id text not null,
  userid text not null,
  timestamp timestamp without time zone not null default current_timestamp,
  device text not null,
  ipaddress text not null,
  constraint loginlog_pkey primary key (id),
  constraint loginlog_userid_fkey foreign key (userid) references public.user(id)
);

create table if not exists public.favorite (
  id text not null,
  userid text not null,
  name text not null,
  accountnumber text not null,
  bankname text not null default 'Mandiri',
  constraint favorite_pkey primary key (id),
  constraint favorite_userid_fkey foreign key (userid) references public.user(id)
);

create index if not exists account_userid_idx on public.account(userid);
create index if not exists transaction_sender_idx on public.transaction(senderaccountid);
create index if not exists transaction_receiver_idx on public.transaction(receiveraccountid);
create index if not exists favorite_userid_idx on public.favorite(userid);
create index if not exists loginlog_userid_idx on public.loginlog(userid);

-- 3) Buka akses untuk mode demo tanpa Supabase Auth.
alter table if exists public.user disable row level security;
alter table if exists public.account disable row level security;
alter table if exists public.transaction disable row level security;
alter table if exists public.loginlog disable row level security;
alter table if exists public.favorite disable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on table public.user to anon, authenticated;
grant select, insert, update, delete on table public.account to anon, authenticated;
grant select, insert, update, delete on table public.transaction to anon, authenticated;
grant select, insert, update, delete on table public.loginlog to anon, authenticated;
grant select, insert, update, delete on table public.favorite to anon, authenticated;

-- 4) Bersihkan data dummy lama dari script ini saja, lalu isi data dummy baru.
delete from public.transaction where id like 'TRX-DEMO-%';
delete from public.favorite where id like 'FAV-DEMO-%';
delete from public.account where id like 'ACC-DEMO-%';
delete from public.user where id like 'USR-DEMO-%';

-- Semua password dummy: 12341234.
-- Email memakai domain demo agar tidak bentrok dengan akun yang dibuat dari aplikasi.
insert into public.user (id, username, password, email, fullname, updatedat)
values
  ('USR-DEMO-NURIL', 'nuril', '12341234', 'nuril.demo@example.com', 'Nuril Anwar', current_timestamp),
  ('USR-DEMO-AHMAD', 'ahmad', '12341234', 'ahmad.demo@example.com', 'Ahmad Syarifuddin', current_timestamp),
  ('USR-DEMO-SISKA', 'siska', '12341234', 'siska.demo@example.com', 'Siska Amelia', current_timestamp);

insert into public.account (id, userid, accountnumber, balance, bankname)
values
  ('ACC-DEMO-NURIL', 'USR-DEMO-NURIL', '1234567890', 12450000, 'Mandiri'),
  ('ACC-DEMO-AHMAD', 'USR-DEMO-AHMAD', '8290012345', 5000000, 'Mandiri'),
  ('ACC-DEMO-SISKA', 'USR-DEMO-SISKA', '8820123456', 3500000, 'Mandiri');

insert into public.favorite (id, userid, name, accountnumber, bankname)
values
  ('FAV-DEMO-AHMAD', 'USR-DEMO-NURIL', 'Ahmad Syarifuddin', '8290012345', 'Mandiri'),
  ('FAV-DEMO-SISKA', 'USR-DEMO-NURIL', 'Siska Amelia', '8820123456', 'Mandiri');

insert into public.transaction (
  id,
  senderaccountid,
  receiveraccountid,
  amount,
  fee,
  note,
  status,
  referencenumber,
  createdat
)
values
  (
    'TRX-DEMO-001',
    'ACC-DEMO-AHMAD',
    'ACC-DEMO-NURIL',
    250000,
    0,
    'Transfer masuk dummy',
    'SUCCESS',
    'REF-DEMO-001',
    current_timestamp - interval '2 days'
  ),
  (
    'TRX-DEMO-002',
    'ACC-DEMO-NURIL',
    'ACC-DEMO-SISKA',
    125000,
    2500,
    'Transfer keluar dummy',
    'SUCCESS',
    'REF-DEMO-002',
    current_timestamp - interval '1 day'
  );
