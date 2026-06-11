import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool biometricLoginEnabled;
  final bool biometricTransactionEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool transactionAlertsEnabled;
  final String languageCode;
  final bool darkModeEnabled;
  final bool twoFactorEnabled;

  const AppSettings({
    this.biometricLoginEnabled = false,
    this.biometricTransactionEnabled = false,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.transactionAlertsEnabled = true,
    this.languageCode = 'id',
    this.darkModeEnabled = false,
    this.twoFactorEnabled = false,
  });

  AppSettings copyWith({
    bool? biometricLoginEnabled,
    bool? biometricTransactionEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? transactionAlertsEnabled,
    String? languageCode,
    bool? darkModeEnabled,
    bool? twoFactorEnabled,
  }) {
    return AppSettings(
      biometricLoginEnabled:
          biometricLoginEnabled ?? this.biometricLoginEnabled,
      biometricTransactionEnabled:
          biometricTransactionEnabled ?? this.biometricTransactionEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      transactionAlertsEnabled:
          transactionAlertsEnabled ?? this.transactionAlertsEnabled,
      languageCode: languageCode ?? this.languageCode,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }
}

class SettingsService {
  SettingsService._();

  static const _biometricLoginKey = 'settings_biometric_login';
  static const _biometricTransactionKey = 'settings_biometric_transaction';
  static const _pushNotificationsKey = 'settings_push_notifications';
  static const _emailNotificationsKey = 'settings_email_notifications';
  static const _transactionAlertsKey = 'settings_transaction_alerts';
  static const _languageKey = 'settings_language';
  static const _darkModeKey = 'settings_dark_mode';
  static const _twoFactorKey = 'settings_two_factor';

  static AppSettings _cache = const AppSettings();

  static AppSettings get current => _cache;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cache = AppSettings(
      biometricLoginEnabled: prefs.getBool(_biometricLoginKey) ?? false,
      biometricTransactionEnabled:
          prefs.getBool(_biometricTransactionKey) ?? false,
      pushNotificationsEnabled: prefs.getBool(_pushNotificationsKey) ?? true,
      emailNotificationsEnabled: prefs.getBool(_emailNotificationsKey) ?? true,
      transactionAlertsEnabled: prefs.getBool(_transactionAlertsKey) ?? true,
      languageCode: prefs.getString(_languageKey) ?? 'id',
      darkModeEnabled: prefs.getBool(_darkModeKey) ?? false,
      twoFactorEnabled: prefs.getBool(_twoFactorKey) ?? false,
    );
    return _cache;
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLoginKey, settings.biometricLoginEnabled);
    await prefs.setBool(
        _biometricTransactionKey, settings.biometricTransactionEnabled);
    await prefs.setBool(_pushNotificationsKey, settings.pushNotificationsEnabled);
    await prefs.setBool(
        _emailNotificationsKey, settings.emailNotificationsEnabled);
    await prefs.setBool(
        _transactionAlertsKey, settings.transactionAlertsEnabled);
    await prefs.setString(_languageKey, settings.languageCode);
    await prefs.setBool(_darkModeKey, settings.darkModeEnabled);
    await prefs.setBool(_twoFactorKey, settings.twoFactorEnabled);
    _cache = settings;
  }

  static String languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English (EN)';
      default:
        return 'Indonesia (ID)';
    }
  }
}
