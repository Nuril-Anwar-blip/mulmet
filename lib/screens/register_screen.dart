import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _passVisible = false;
  bool _confirmPassVisible = false;
  bool _termsAccepted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sama.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await BankService.register(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
          'Bank Mandiri',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Akun Baru',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lengkapi data diri Anda untuk menikmati layanan perbankan digital masa depan.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Lengkap'),
                  const SizedBox(height: 6),
                  _buildField(_nameController, 'Masukkan nama sesuai KTP',
                      Icons.person_outline),
                  const SizedBox(height: 14),
                  _buildLabel('NIK (No. KTP)'),
                  const SizedBox(height: 6),
                  _buildField(_nikController, '16 digit nomor identitas',
                      Icons.badge_outlined,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _buildLabel('Nomor Telepon'),
                  const SizedBox(height: 6),
                  _buildField(_phoneController, '08xx xxxx xxxx',
                      Icons.phone_iphone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  _buildField(_emailController, 'contoh@email.com',
                      Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildLabel('Buat Password'),
                  const SizedBox(height: 6),
                  _buildPasswordField(_passController, 'Minimal 8 karakter',
                      _passVisible, () {
                    setState(() => _passVisible = !_passVisible);
                  }),
                  const SizedBox(height: 14),
                  _buildLabel('Konfirmasi Password'),
                  const SizedBox(height: 6),
                  _buildPasswordField(_confirmPassController, 'Ulangi password',
                      _confirmPassVisible, () {
                    setState(
                        () => _confirmPassVisible = !_confirmPassVisible);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) =>
                      setState(() => _termsAccepted = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 13, color: AppColors.secondary),
                        children: [
                          const TextSpan(text: 'Saya menyetujui '),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: GoogleFonts.hankenGrotesk(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                          const TextSpan(text: ' serta '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: GoogleFonts.hankenGrotesk(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                          const TextSpan(text: ' Bank Mandiri.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _termsAccepted && !_isLoading
                    ? _handleRegister
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Daftar Sekarang',
                        style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sudah punya akun?  ',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.secondary)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Masuk',
                    style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.hankenGrotesk(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.hankenGrotesk(
              color: AppColors.outline.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: AppColors.outline, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool visible,
    VoidCallback onToggle,
  ) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        style: GoogleFonts.hankenGrotesk(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.hankenGrotesk(
              color: AppColors.outline.withValues(alpha: 0.6)),
          prefixIcon:
              const Icon(Icons.lock_outline, color: AppColors.outline, size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.outline,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
