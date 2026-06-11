import '../services/settings_service.dart';

class AppStrings {
  AppStrings._();

  static const _strings = <String, Map<String, String>>{
    'app_title': {'id': 'Bank Mandiri', 'en': 'Bank Mandiri'},
    'home': {'id': 'Beranda', 'en': 'Home'},
    'transfer': {'id': 'Transfer', 'en': 'Transfer'},
    'history': {'id': 'Riwayat', 'en': 'History'},
    'profile': {'id': 'Profil', 'en': 'Profile'},
    'qris': {'id': 'QRIS', 'en': 'QRIS'},
    'notifications': {'id': 'Notifikasi', 'en': 'Notifications'},
    'more_services': {'id': 'Layanan Lainnya', 'en': 'More Services'},
    'favorites': {'id': 'Daftar Favorit', 'en': 'Favorites'},
    'deposito': {'id': 'Deposito', 'en': 'Deposit'},
    'credit_card': {'id': 'Kartu Kredit', 'en': 'Credit Card'},
    'pulsa': {'id': 'Pulsa & Data', 'en': 'Pulsa & Data'},
    'pln': {'id': 'PLN', 'en': 'Electricity'},
    'login_history': {'id': 'Riwayat Login', 'en': 'Login History'},
    'financial_chart': {'id': 'Grafik Keuangan', 'en': 'Financial Chart'},
    'scheduled_transfer': {'id': 'Transfer Terjadwal', 'en': 'Scheduled Transfer'},
    'my_qris': {'id': 'QRIS Saya', 'en': 'My QRIS'},
    'export': {'id': 'Ekspor', 'en': 'Export'},
    'dark_mode': {'id': 'Mode Gelap', 'en': 'Dark Mode'},
    'two_factor': {'id': 'Verifikasi OTP', 'en': 'OTP Verification'},
    'save': {'id': 'Simpan', 'en': 'Save'},
    'cancel': {'id': 'Batal', 'en': 'Cancel'},
    'pay': {'id': 'Bayar', 'en': 'Pay'},
    'balance': {'id': 'Saldo', 'en': 'Balance'},
    'success': {'id': 'Berhasil', 'en': 'Success'},
    'coming_soon': {'id': 'Segera hadir', 'en': 'Coming soon'},
  };

  static String t(String key) {
    final lang = SettingsService.current.languageCode;
    return _strings[key]?[lang] ?? _strings[key]?['id'] ?? key;
  }
}
