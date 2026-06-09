import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'history_screen.dart';
import 'login_screen.dart';
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

  @override
  void initState() {
    super.initState();
    final user = SessionManager.currentUser;
    if (user != null) {
      _emailController.text = user.email;
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            onPressed: () {},
          ),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
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
                  child: const Icon(Icons.person,
                      size: 56, color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perubahan berhasil disimpan')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: Text('Simpan Perubahan',
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
        onTap: () {},
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        SessionManager.clear();
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
