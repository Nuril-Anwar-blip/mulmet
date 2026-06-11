import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../services/biometric_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  AppSettings _settings = SettingsService.current;
  bool _deviceSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.load();
    final supported = await BiometricService.isDeviceSupported();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _deviceSupported = supported;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometricLogin(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Aktifkan login biometrik',
      );
      if (!authenticated) return;
    }
    final updated = _settings.copyWith(biometricLoginEnabled: value);
    await SettingsService.save(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
  }

  Future<void> _toggleBiometricTransaction(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Aktifkan biometrik transaksi',
      );
      if (!authenticated) return;
    }
    final updated = _settings.copyWith(biometricTransactionEnabled: value);
    await SettingsService.save(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Keamanan',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildSwitchTile(
                  title: 'Login Biometrik',
                  subtitle: 'Masuk dengan sidik jari atau wajah',
                  value: _settings.biometricLoginEnabled,
                  enabled: _deviceSupported,
                  onChanged: _toggleBiometricLogin,
                ),
                _buildSwitchTile(
                  title: 'Biometrik Transaksi',
                  subtitle: 'Konfirmasi transfer dan QRIS dengan biometrik',
                  value: _settings.biometricTransactionEnabled,
                  enabled: _deviceSupported,
                  onChanged: _toggleBiometricTransaction,
                ),
                _buildSwitchTile(
                  title: 'Verifikasi OTP',
                  subtitle: 'Kode OTP saat login dan transaksi besar',
                  value: _settings.twoFactorEnabled,
                  enabled: true,
                  onChanged: (value) async {
                    final updated =
                        _settings.copyWith(twoFactorEnabled: value);
                    await SettingsService.save(updated);
                    if (!mounted) return;
                    setState(() => _settings = updated);
                  },
                ),
                _buildSwitchTile(
                  title: 'Mode Gelap',
                  subtitle: 'Tampilan aplikasi gelap',
                  value: _settings.darkModeEnabled,
                  enabled: true,
                  onChanged: (value) async {
                    final updated =
                        _settings.copyWith(darkModeEnabled: value);
                    await SettingsService.save(updated);
                    BankMandiriApp.refreshSettings();
                    if (!mounted) return;
                    setState(() => _settings = updated);
                  },
                ),
                const SizedBox(height: 12),
                _buildTipsCard(),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _deviceSupported
                  ? 'Perangkat Anda mendukung autentikasi biometrik.'
                  : 'Perangkat ini tidak mendukung biometrik. Gunakan PIN transaksi.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 12, color: AppColors.secondary)),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips Keamanan',
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...[
            'Jangan bagikan PIN transaksi kepada siapa pun.',
            'Aktifkan biometrik untuk lapisan keamanan tambahan.',
            'Keluar dari aplikasi setelah selesai bertransaksi.',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
