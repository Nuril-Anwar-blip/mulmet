import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_service.dart';

class OtpService {
  OtpService._();

  static const _otpKeyPrefix = 'otp_code';
  static const _otpExpiryPrefix = 'otp_expiry';

  static bool get isEnabled => SettingsService.current.twoFactorEnabled;

  static String _otpKey(String userId) => '$_otpKeyPrefix:$userId';
  static String _expiryKey(String userId) => '$_otpExpiryPrefix:$userId';

  static Future<String> generateOtp(String userId) async {
    final code = List.generate(6, (_) => Random().nextInt(10)).join();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpKey(userId), code);
    await prefs.setInt(
      _expiryKey(userId),
      DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
    );
    return code;
  }

  static Future<bool> verifyOtp(String userId, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_otpKey(userId));
    final expiry = prefs.getInt(_expiryKey(userId));
    if (saved == null || expiry == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > expiry) return false;
    return saved == code.trim();
  }

  static Future<void> clearOtp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpKey(userId));
    await prefs.remove(_expiryKey(userId));
  }

  static bool requiresOtpForAmount(double amount) =>
      isEnabled || amount >= 5000000;
}
