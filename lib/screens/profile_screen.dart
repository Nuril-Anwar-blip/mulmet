import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bank_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/notification_icon_button.dart';
import 'financial_chart_screen.dart';
import 'history_screen.dart';
import 'language_screen.dart';
import 'login_history_screen.dart';
import 'login_screen.dart';
import 'my_qris_screen.dart';
import 'notification_screen.dart';
import 'scheduled_transfer_screen.dart';
import 'security_screen.dart';
import 'transfer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController =
      TextEditingController(text: 'aditya.pratama@email.com');
  final _phoneController =
      TextEditingController(text: '+62 812 3456 7890');
  bool _isSaving = false;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    final user = SessionManager.currentUser;
    if (user != null) {
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _loadPhoto(user.id);
    }
  }

  Future<void> _loadPhoto(String userId) async {
    final photo = await ProfilePhotoService.getPhoto(userId);
    if (!mounted) return;
    setState(() => _photoBase64 = photo);
  }

  Future<void> _pickPhoto() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    final photo = await ProfilePhotoService.pickAndSave(user.id);
    if (!mounted || photo == null) return;
    setState(() => _photoBase64 = photo);
  }

  Future<void> _saveProfile() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
        .hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email belum valid.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await BankService.updateProfile(email: email, phone: phone);
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan berhasil disimpan')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showChangePinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah PIN',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pinField(oldPinController, 'PIN Lama'),
            const SizedBox(height: 10),
            _pinField(newPinController, 'PIN Baru'),
            const SizedBox(height: 10),
            _pinField(confirmPinController, 'Konfirmasi PIN Baru'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPin = oldPinController.text.trim();
              final newPin = newPinController.text.trim();
              final confirmPin = confirmPinController.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(newPin)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN baru harus 6 digit angka.')),
                );
                return;
              }
              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi PIN tidak sama.')),
                );
                return;
              }
              try {
                await BankService.changeTransactionPin(
                  oldPin: oldPin,
                  newPin: newPin,
                );
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN berhasil diperbarui.')),
                );
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    oldPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        actions: const [
          NotificationIconButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // Profile hero
          _buildProfileHero(),
          const SizedBox(height: 28),
          // Personal info form
          _buildPersonalInfo(),
          const SizedBox(height: 28),
          // Settings
          _buildSettingsSection(),
          const SizedBox(height: 28),
          // Logout
          _buildLogoutSection(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TransferScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileHero() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondaryContainer,
                  ),
                  child: _photoBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_photoBase64!),
                            width: 106,
                            height: 106,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 56, color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.photo_camera,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          SessionManager.currentUser?.fullName ?? 'Nasabah Mandiri',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Nasabah Prioritas',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel('Alamat Email'),
        const SizedBox(height: 6),
        _buildEditableField(_emailController, Icons.email_outlined),
        const SizedBox(height: 14),
        _buildFormLabel('Nomor Telepon'),
        const SizedBox(height: 6),
        _buildEditableField(_phoneController, Icons.phone_iphone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.hankenGrotesk(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
          suffixIcon:
              const Icon(Icons.edit_outlined, color: AppColors.secondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final items = [
      {
        'icon': Icons.password_outlined,
        'title': 'Ubah PIN',
        'subtitle': 'Amankan transaksi Anda'
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Keamanan',
        'subtitle': 'Biometrik & perangkat'
      },
      {
        'icon': Icons.notifications_active_outlined,
        'title': 'Notifikasi',
        'subtitle': 'Atur pemberitahuan Anda'
      },
      {
        'icon': Icons.language_outlined,
        'title': 'Bahasa',
        'subtitle': 'Indonesia (ID)'
      },
      {
        'icon': Icons.qr_code_2,
        'title': 'QRIS Saya',
        'subtitle': 'Terima pembayaran'
      },
      {
        'icon': Icons.schedule,
        'title': 'Transfer Terjadwal',
        'subtitle': 'Jadwalkan transfer'
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Grafik Keuangan',
        'subtitle': 'Ringkasan arus kas'
      },
      {
        'icon': Icons.devices,
        'title': 'Riwayat Login',
        'subtitle': 'Perangkat & aktivitas'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan Akun',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: items.map((item) => _buildSettingCard(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingCard(Map<String, dynamic> item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          final title = item['title'] as String;
          if (title == 'Ubah PIN') {
            _showChangePinDialog();
          } else if (title == 'Keamanan') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecurityScreen()),
            );
          } else if (title == 'Notifikasi') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          } else if (title == 'Bahasa') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguageScreen()),
            );
          } else if (title == 'QRIS Saya') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyQrisScreen()),
            );
          } else if (title == 'Transfer Terjadwal') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ScheduledTransferScreen()),
            );
          } else if (title == 'Grafik Keuangan') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FinancialChartScreen()),
            );
          } else if (title == 'Riwayat Login') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LoginHistoryScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      item['subtitle'] as String,
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 11, color: AppColors.secondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Keluar',
                      style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600)),
                  content: Text('Apakah Anda yakin ingin keluar?',
                      style: GoogleFonts.hankenGrotesk()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await BankService.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      child: Text('Keluar',
                          style: GoogleFonts.hankenGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(
              'Keluar',
              style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w600, color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Versi Aplikasi 4.2.0 (Stable)',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 12, color: AppColors.outlineVariant),
        ),
      ],
    );
  }
}
