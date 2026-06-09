# Bank Mandiri - Flutter Mobile Banking App

Aplikasi mobile banking Bank Mandiri yang dibangun dengan Flutter, mengkonversi desain HTML/Tailwind menjadi kode Flutter native yang lengkap.

---

## 📱 Screens yang Tersedia

| Screen | File | Deskripsi |
|---|---|---|
| Login | `login_screen.dart` | Halaman masuk dengan username/password & biometrik |
| Dashboard | `dashboard_screen.dart` | Beranda utama dengan saldo, quick actions, transaksi |
| Transfer | `transfer_screen.dart` | Form transfer dana |
| Pilih Bank | `bank_select_screen.dart` | Pilihan bank tujuan transfer (populer + daftar A-Z) |
| Tambah Penerima | `add_recipient_screen.dart` | Input & verifikasi nomor rekening penerima |
| Konfirmasi | `confirm_transaction_screen.dart` | Konfirmasi transaksi + PIN / biometrik |
| Struk / Resi | `receipt_screen.dart` | Bukti transfer berhasil |
| Riwayat | `history_screen.dart` | Daftar transaksi dengan filter & detail expandable |
| Profil | `profile_screen.dart` | Informasi pengguna & pengaturan akun |
| Registrasi | `register_screen.dart` | Pendaftaran akun baru |

---

## 🚀 Cara Menjalankan

### Prasyarat
- Flutter SDK **≥ 3.0.0**
- Dart SDK **≥ 3.0.0**
- Android Studio / VS Code dengan plugin Flutter

### Langkah

```bash
# 1. Masuk ke folder project
cd bank_mandiri_flutter

# 2. Install dependensi
flutter pub get

# 3. Jalankan di emulator/device
flutter run
```

---

## 🗂️ Struktur Project

```
lib/
├── main.dart                          # Entry point aplikasi
├── theme/
│   └── app_theme.dart                 # Warna, typography, ThemeData
├── models/
│   └── models.dart                    # Model data (Transaction, Bank, dummy data)
├── widgets/
│   └── bottom_nav.dart                # Bottom navigation bar (shared widget)
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── dashboard_screen.dart
    ├── transfer_screen.dart
    ├── bank_select_screen.dart
    ├── add_recipient_screen.dart
    ├── confirm_transaction_screen.dart
    ├── receipt_screen.dart
    ├── history_screen.dart
    └── profile_screen.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0    # Font Hanken Grotesk (sesuai desain asli)
  intl: ^0.18.1           # Format mata uang Rupiah (Rp)
```

---

## 🎨 Design System

Mengikuti token desain dari HTML asli:

| Token | Nilai |
|---|---|
| `primary` | `#001831` (Navy gelap) |
| `primaryContainer` | `#002D54` |
| `onPrimaryContainer` | `#7495C2` (Biru muda) |
| `secondary` | `#505F76` |
| `surface` | `#F7F9FB` (Abu terang) |
| Font | Hanken Grotesk |

---

## ✨ Fitur Utama

- **Animasi masuk** pada setiap screen (fade + slide)
- **Toggle saldo** tersembunyi di dashboard
- **PIN input** visual dengan numpad
- **Verifikasi rekening** dengan animasi loading
- **History expandable** — tap transaksi untuk detail
- **Search & filter** di halaman riwayat
- **Konfirmasi logout** dengan dialog
- **Receipt screen** dengan efek tear (robek struk)
- Bottom navigation konsisten di semua screen
- Format angka Rupiah dengan `intl` (`Rp 12.450.000`)

---

## 🔗 Alur Navigasi

```
LoginScreen
    ├── RegisterScreen
    └── DashboardScreen
            ├── TransferScreen
            │       ├── BankSelectScreen
            │       └── AddRecipientScreen
            │               └── ConfirmTransactionScreen
            │                       └── ReceiptScreen
            ├── HistoryScreen
            └── ProfileScreen
                    └── LoginScreen (Logout)
```

---

## 📝 Catatan

- Data yang digunakan adalah **dummy data** statis (lihat `models.dart`)
- Tidak ada state management eksternal — menggunakan `setState` bawaan Flutter
- Siap dikembangkan lebih lanjut dengan **Provider**, **Riverpod**, atau **BLoC**
- Siap diintegrasikan dengan **REST API** nyata Bank Mandiri
