-- Jalankan file ini di Supabase SQL Editor jika aplikasi menampilkan:
-- "new row violates row-level security policy".
--
-- Aplikasi demo ini tidak memakai Supabase Auth; request Flutter memakai
-- publishable/anon key. Karena itu tabel demo perlu bisa diakses oleh role anon.

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

insert into public.user (id, username, password, email, fullname, updatedat)
values
  ('USR-DEMO-RECEIVER', 'ahmad', '12341234', 'ahmad.demo@example.com', 'Ahmad Syarifuddin', current_timestamp)
on conflict (id) do nothing;

insert into public.account (id, userid, accountnumber, balance, bankname)
values
  ('ACC-DEMO-RECEIVER', 'USR-DEMO-RECEIVER', '8290012345', 5000000, 'Mandiri')
on conflict (accountnumber) do nothing;
