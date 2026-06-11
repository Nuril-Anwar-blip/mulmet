-- Skema fitur tambahan. Jalankan setelah production_schema.sql.

create table if not exists public.deposit (
  id text primary key,
  userid text not null references public.user(id),
  amount double precision not null,
  interestrate double precision not null default 5.5,
  termmonths integer not null,
  startdate timestamp without time zone not null default current_timestamp,
  maturitydate timestamp without time zone not null,
  status text not null default 'ACTIVE'
);

create table if not exists public.credit_card (
  id text primary key,
  userid text not null references public.user(id),
  cardnumber text not null,
  creditlimit double precision not null,
  usedamount double precision not null default 0,
  minimumpayment double precision not null default 0,
  duedate timestamp without time zone not null
);

create table if not exists public.scheduled_transfer (
  id text primary key,
  userid text not null references public.user(id),
  receiveraccountnumber text not null,
  receiverbankname text not null,
  receivername text not null,
  amount double precision not null,
  frequency text not null,
  nextrundate timestamp without time zone not null,
  status text not null default 'ACTIVE'
);

create table if not exists public.utility_payment (
  id text primary key,
  userid text not null references public.user(id),
  type text not null,
  customerid text not null,
  customername text not null,
  amount double precision not null,
  createdat timestamp without time zone not null default current_timestamp
);

create table if not exists public.password_reset (
  userid text primary key references public.user(id),
  token text not null,
  expiresat timestamp without time zone not null
);

alter table if exists public.deposit disable row level security;
alter table if exists public.credit_card disable row level security;
alter table if exists public.scheduled_transfer disable row level security;
alter table if exists public.utility_payment disable row level security;
alter table if exists public.password_reset disable row level security;

grant select, insert, update, delete on table public.deposit to anon, authenticated;
grant select, insert, update, delete on table public.credit_card to anon, authenticated;
grant select, insert, update, delete on table public.scheduled_transfer to anon, authenticated;
grant select, insert, update, delete on table public.utility_payment to anon, authenticated;
grant select, insert, update, delete on table public.password_reset to anon, authenticated;
