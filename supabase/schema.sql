create extension if not exists pgcrypto;

create type public.transaction_status as enum ('pending', 'success', 'failed');
create type public.transaction_type as enum ('transfer_in', 'transfer_out', 'qris_payment', 'bill_payment');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  phone text,
  priority_label text default 'Nasabah Prioritas',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.banks (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  logo_url text,
  is_popular boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  bank_id uuid not null references public.banks(id),
  account_number text not null,
  account_name text not null,
  balance numeric(14, 2) not null default 0 check (balance >= 0),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  unique (bank_id, account_number)
);

create table public.recipients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  bank_id uuid not null references public.banks(id),
  account_number text not null,
  account_name text not null,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, bank_id, account_number)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_account_id uuid references public.accounts(id),
  recipient_id uuid references public.recipients(id),
  type public.transaction_type not null,
  status public.transaction_status not null default 'pending',
  amount numeric(14, 2) not null check (amount > 0),
  admin_fee numeric(14, 2) not null default 0 check (admin_fee >= 0),
  reference_no text unique not null default ('TRF-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  note text,
  created_at timestamptz not null default now()
);

create table public.transfer_details (
  transaction_id uuid primary key references public.transactions(id) on delete cascade,
  transfer_method text not null default 'BI-FAST',
  sender_snapshot jsonb not null,
  recipient_snapshot jsonb not null,
  receipt_url text
);

alter table public.profiles enable row level security;
alter table public.banks enable row level security;
alter table public.accounts enable row level security;
alter table public.recipients enable row level security;
alter table public.transactions enable row level security;
alter table public.transfer_details enable row level security;

create policy "Profiles are visible to owners"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Users can view own accounts"
  on public.accounts for select
  using (auth.uid() = user_id);

create policy "Users can view own recipients"
  on public.recipients for select
  using (auth.uid() = user_id);

create policy "Users can manage own recipients"
  on public.recipients for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can view own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "Users can create own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "Users can view own transfer details"
  on public.transfer_details for select
  using (
    exists (
      select 1
      from public.transactions t
      where t.id = transfer_details.transaction_id
        and t.user_id = auth.uid()
    )
  );

create policy "Banks are readable by authenticated users"
  on public.banks for select
  to authenticated
  using (true);

insert into public.banks (code, name, is_popular) values
  ('008', 'Bank Mandiri', true),
  ('014', 'Bank Central Asia', true),
  ('002', 'Bank Rakyat Indonesia', true),
  ('009', 'BNI', true),
  ('536', 'Bank BCA Syariah', false),
  ('133', 'Bank Bengkulu', false),
  ('200', 'Bank BTN', false),
  ('031', 'Citibank N.A.', false),
  ('950', 'Commonwealth Bank', false),
  ('011', 'Danamon', false)
on conflict (code) do update set
  name = excluded.name,
  is_popular = excluded.is_popular;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nasabah Mandiri'),
    coalesce(new.email, ''),
    new.raw_user_meta_data ->> 'phone'
  );

  insert into public.accounts (user_id, bank_id, account_number, account_name, balance, is_primary)
  select
    new.id,
    b.id,
    lpad((floor(random() * 10000000000))::bigint::text, 10, '0'),
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nasabah Mandiri'),
    12450000,
    true
  from public.banks b
  where b.code = '008'
  limit 1
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
