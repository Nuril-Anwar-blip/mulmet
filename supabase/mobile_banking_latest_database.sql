-- Database terbaru aplikasi mobile banking Flutter.
-- Nama rujukan database/schema: mobile_banking_latest_database
--
-- Jalankan seluruh file ini di Supabase SQL Editor.
-- Tabel yang dipakai Flutter:
-- user, account, transaction, loginlog, favorite
--
-- Akun dummy:
-- username: nuril | password: 12341234 | PIN: 123456
-- username: ahmad | password: 12341234 | PIN: 123456
-- username: siska | password: 12341234 | PIN: 123456

drop table if exists public."Transaction" cascade;
drop table if exists public."Favorite" cascade;
drop table if exists public."LoginLog" cascade;
drop table if exists public."Account" cascade;
drop table if exists public."User" cascade;

create table if not exists public.user (
  id text not null,
  username text not null unique,
  password text not null,
  email text not null unique,
  fullname text not null,
  phone text,
  transactionpin text not null default '123456',
  createdat timestamp without time zone not null default current_timestamp,
  updatedat timestamp without time zone not null default current_timestamp,
  constraint user_pkey primary key (id),
  constraint user_transactionpin_check check (transactionpin ~ '^[0-9]{6}$')
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
  constraint transaction_receiveraccountid_fkey foreign key (receiveraccountid) references public.account(id),
  constraint transaction_amount_check check (amount > 0),
  constraint transaction_fee_check check (fee >= 0)
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

alter table public.user add column if not exists phone text;
alter table public.user add column if not exists transactionpin text default '123456';
update public.user
set transactionpin = '123456'
where transactionpin is null;
alter table public.user alter column transactionpin set default '123456';
alter table public.user alter column transactionpin set not null;

create index if not exists account_userid_idx on public.account(userid);
create index if not exists transaction_sender_idx on public.transaction(senderaccountid);
create index if not exists transaction_receiver_idx on public.transaction(receiveraccountid);
create index if not exists favorite_userid_idx on public.favorite(userid);
create index if not exists loginlog_userid_idx on public.loginlog(userid);

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

create or replace function public.create_transfer_atomic(
  p_sender_account_id text,
  p_receiver_account_number text,
  p_receiver_bank_name text,
  p_amount double precision,
  p_fee double precision default 6500,
  p_note text default null
)
returns table (
  id text,
  senderaccountid text,
  receiveraccountid text,
  amount double precision,
  fee double precision,
  note text,
  status text,
  referencenumber text,
  createdat timestamp without time zone
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender public.account%rowtype;
  v_receiver public.account%rowtype;
  v_transaction_id text;
  v_reference text;
begin
  if p_amount <= 0 then
    raise exception 'Nominal transfer harus lebih dari 0.';
  end if;

  if p_fee < 0 then
    raise exception 'Biaya admin tidak valid.';
  end if;

  select *
  into v_sender
  from public.account a
  where a.id = p_sender_account_id
  for update;

  if not found then
    raise exception 'Rekening sumber tidak ditemukan.';
  end if;

  select *
  into v_receiver
  from public.account a
  where a.accountnumber = p_receiver_account_number
    and a.bankname = p_receiver_bank_name
  for update;

  if not found then
    raise exception 'Rekening tujuan tidak ditemukan di database.';
  end if;

  if v_sender.id = v_receiver.id then
    raise exception 'Tidak bisa transfer ke rekening sendiri.';
  end if;

  if v_sender.balance < (p_amount + p_fee) then
    raise exception 'Saldo tidak mencukupi.';
  end if;

  update public.account
  set balance = balance - (p_amount + p_fee)
  where id = v_sender.id;

  update public.account
  set balance = balance + p_amount
  where id = v_receiver.id;

  v_transaction_id := 'TRX-' || extract(epoch from clock_timestamp())::bigint || '-' || floor(random() * 10000)::int;
  v_reference := 'TRF-' || extract(epoch from clock_timestamp())::bigint || floor(random() * 10000)::int;

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
  values (
    v_transaction_id,
    v_sender.id,
    v_receiver.id,
    p_amount,
    p_fee,
    p_note,
    'SUCCESS',
    v_reference,
    current_timestamp
  );

  return query
  select
    t.id,
    t.senderaccountid,
    t.receiveraccountid,
    t.amount,
    t.fee,
    t.note,
    t.status,
    t.referencenumber,
    t.createdat
  from public.transaction t
  where t.id = v_transaction_id;
end;
$$;

grant execute on function public.create_transfer_atomic(
  text,
  text,
  text,
  double precision,
  double precision,
  text
) to anon, authenticated;

delete from public.transaction
where id like 'TRX-DEMO-%'
   or senderaccountid like 'ACC-DEMO-%'
   or receiveraccountid like 'ACC-DEMO-%';
delete from public.favorite where id like 'FAV-DEMO-%';
delete from public.account where id like 'ACC-DEMO-%';
delete from public.loginlog where userid like 'USR-DEMO-%';
delete from public.user where id like 'USR-DEMO-%';

insert into public.user (
  id,
  username,
  password,
  email,
  fullname,
  phone,
  transactionpin,
  updatedat
)
values
  ('USR-DEMO-NURIL', 'nuril', '12341234', 'nuril.demo@example.com', 'Nuril Anwar', '0895623147897', '123456', current_timestamp),
  ('USR-DEMO-AHMAD', 'ahmad', '12341234', 'ahmad.demo@example.com', 'Ahmad Syarifuddin', '081234567890', '123456', current_timestamp),
  ('USR-DEMO-SISKA', 'siska', '12341234', 'siska.demo@example.com', 'Siska Amelia', '082345678901', '123456', current_timestamp)
on conflict (id) do update set
  username = excluded.username,
  password = excluded.password,
  email = excluded.email,
  fullname = excluded.fullname,
  phone = excluded.phone,
  transactionpin = excluded.transactionpin,
  updatedat = current_timestamp;

insert into public.account (id, userid, accountnumber, balance, bankname)
values
  ('ACC-DEMO-NURIL', 'USR-DEMO-NURIL', '1234567890', 12450000, 'Mandiri'),
  ('ACC-DEMO-AHMAD', 'USR-DEMO-AHMAD', '8290012345', 5000000, 'Mandiri'),
  ('ACC-DEMO-SISKA', 'USR-DEMO-SISKA', '8820123456', 3500000, 'Mandiri')
on conflict (accountnumber) do update set
  userid = excluded.userid,
  balance = excluded.balance,
  bankname = excluded.bankname;

insert into public.favorite (id, userid, name, accountnumber, bankname)
values
  ('FAV-DEMO-AHMAD', 'USR-DEMO-NURIL', 'Ahmad Syarifuddin', '8290012345', 'Mandiri'),
  ('FAV-DEMO-SISKA', 'USR-DEMO-NURIL', 'Siska Amelia', '8820123456', 'Mandiri')
on conflict (id) do update set
  userid = excluded.userid,
  name = excluded.name,
  accountnumber = excluded.accountnumber,
  bankname = excluded.bankname;

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
  )
on conflict (referencenumber) do update set
  senderaccountid = excluded.senderaccountid,
  receiveraccountid = excluded.receiveraccountid,
  amount = excluded.amount,
  fee = excluded.fee,
  note = excluded.note,
  status = excluded.status,
  createdat = excluded.createdat;
