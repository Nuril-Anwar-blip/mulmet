import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_service.dart';

class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();
  static const _lastUserIdKey = 'biometric_last_user_id';

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> authenticate({
    required String reason,
  }) async {
    final supported = await isDeviceSupported();
    if (!supported) {
      throw Exception('Perangkat tidak mendukung autentikasi biometrik.');
    }

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveBiometricUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, userId);
  }

  static Future<String?> getBiometricUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUserIdKey);
  }

  static Future<void> clearBiometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
  }

  static Future<bool> canUseLoginBiometric() async {
    await SettingsService.load();
    if (!SettingsService.current.biometricLoginEnabled) return false;
    final userId = await getBiometricUserId();
    if (userId == null || userId.isEmpty) return false;
    return await canCheckBiometrics();
  }

  static Future<bool> canUseTransactionBiometric() async {
    await SettingsService.load();
    if (!SettingsService.current.biometricTransactionEnabled) return false;
    return await canCheckBiometrics();
  }
}
