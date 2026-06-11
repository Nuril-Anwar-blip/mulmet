# Bank Mandiri Mobile Banking

Aplikasi mobile banking Bank Mandiri. Semua fitur utama sudah terhubung ke layar dan layanan nyata, bukan mode demo.

## Fitur Lengkap

| Fitur | File |
|---|---|
| Login + Biometrik | `login_screen.dart`, `biometric_service.dart` |
| Dashboard | `dashboard_screen.dart` |
| Transfer + Ganti Rekening | `transfer_screen.dart`, `account_select_screen.dart` |
| QRIS | `qris_screen.dart`, `qris_confirm_screen.dart` |
| Tagihan | `bill_screen.dart` |
| Notifikasi | `notification_screen.dart`, `notification_service.dart` |
| Riwayat | `history_screen.dart` |
| Profil + Keamanan + Bahasa | `profile_screen.dart`, `security_screen.dart`, `language_screen.dart` |
| Layanan Lainnya | `more_services_screen.dart` |
| Lupa Password | `forgot_password_screen.dart` |

## Setup Database

1. Jalankan `supabase/mobile_banking_latest_database.sql`
2. Jalankan `supabase/production_schema.sql` untuk tabel notifikasi dan label rekening
3. Isi kredensial Supabase di `.env` atau `lib/supabase_config.dart`

## Menjalankan

```powershell
cd tugas_akhir_bank
flutter pub get
flutter run
```

## Akun Uji

- Username: `nuril` | Password: `12341234` | PIN: `123456`
- Username: `ahmad` | Password: `12341234` | PIN: `123456`
- Username: `siska` | Password: `12341234` | PIN: `123456`

## Fitur Lengkap

| Kategori | Fitur |
|---|---|
| Transfer | Transfer dana, ganti rekening, transfer terjadwal, kelola favorit |
| Pembayaran | QRIS scan, QRIS terima, tagihan, PLN, pulsa |
| Keuangan | Deposito, kartu kredit, grafik keuangan, ekspor CSV |
| Keamanan | Biometrik, OTP 2FA, reset password token, riwayat login |
| Profil | Foto profil, notifikasi, bahasa ID/EN, mode gelap |

## Setup Database

1. `supabase/mobile_banking_latest_database.sql`
2. `supabase/production_schema.sql`
3. `supabase/features_schema.sql`

## Catatan

- Beberapa fitur menggunakan fallback lokal jika tabel Supabase belum dibuat
- OTP demo: kode ditampilkan di layar verifikasi
- Reset password: kode dikirim ke notifikasi in-app
