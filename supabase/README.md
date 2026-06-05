# Supabase setup

1. Buka Supabase Dashboard.
2. Masuk ke SQL Editor.
3. Jalankan isi file `schema.sql`.
4. Aktifkan Auth Email/Password di menu Authentication.
5. Ambil `Project URL` dan `anon public key` dari Project Settings > API.
6. Isi file `lib/supabase_config.dart`:

```dart
const localSupabaseUrl = 'https://PROJECT_ID.supabase.co';
const localSupabaseAnonKey = 'ANON_PUBLIC_KEY';
```

7. Jalankan Flutter seperti biasa:

```powershell
flutter run
```

Alternatif tanpa mengisi file config:

```powershell
flutter run --dart-define=SUPABASE_URL=https://PROJECT_ID.supabase.co --dart-define=SUPABASE_ANON_KEY=ANON_PUBLIC_KEY
```

Skema ini membuat tabel:

- `profiles` untuk data nasabah.
- `banks` untuk daftar bank tujuan.
- `accounts` untuk rekening milik user.
- `recipients` untuk penerima/favorit transfer.
- `transactions` untuk riwayat transaksi.
- `transfer_details` untuk data struk transfer.

Row Level Security sudah aktif untuk data user. Tabel `banks` bisa dibaca user yang sudah login.

Jika `schema.sql` sudah pernah dijalankan sebelumnya, jalankan juga `update_auth_trigger.sql`.
File itu membuat user baru otomatis punya `profiles` dan rekening utama Mandiri di tabel `accounts`.

Catatan untuk mode demo: jika signup dari aplikasi terkena `email rate limit exceeded`, tunggu beberapa menit atau buat user dari dashboard. Kalau pengaturan Supabase kamu menyediakan opsi email confirmation, matikan confirmation agar signup langsung menghasilkan session dan masuk ke Beranda.
