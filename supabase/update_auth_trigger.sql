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
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    phone = excluded.phone,
    updated_at = now();

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
