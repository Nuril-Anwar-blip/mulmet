import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bank_service.dart';
import '../services/biometric_service.dart';
import '../services/otp_service.dart';
import '../services/settings_service.dart';
import 'otp_verify_screen.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    await SettingsService.load();
    final canUse = await BiometricService.canUseLoginBiometric();
    if (!mounted) return;
    setState(() => _biometricEnabled = canUse);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final credential = _usernameController.text.trim();
    final password = _passwordController.text;
    if (credential.isEmpty || password.isEmpty) {
      _showMessage('Username/email dan password wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await BankService.login(
        usernameOrEmail: credential,
        password: password,
      );
      if (_biometricEnabled) {
        await BiometricService.saveBiometricUser(user.id);
      }

      if (OtpService.isEnabled) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        final otp = await OtpService.generateOtp(user.id);
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyScreen(
              userId: user.id,
              otpCode: otp,
              onVerified: () {},
            ),
          ),
        );
        if (verified != true) return;
      }

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    try {
      final userId = await BiometricService.getBiometricUserId();
      if (userId == null) {
        throw Exception('Login biometrik belum diaktifkan.');
      }

      final authenticated = await BiometricService.authenticate(
        reason: 'Masuk ke Bank Mandiri',
      );
      if (!authenticated) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final restored = await BankService.restoreSessionForUser(userId);
      if (!restored) {
        throw Exception('Sesi biometrik kedaluwarsa. Login dengan password.');
      }

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top branding section
            _buildBrandingSection(),
            // Form card
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildFormCard(context),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Security badge
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.outline.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'SECURE ENCRYPTED LOGIN',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: AppColors.outline.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative blobs
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onPrimaryContainer.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Bank Mandiri',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selamat Datang Kembali',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola keuangan Anda dengan aman',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username or email field
          _buildLabel('Username / Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _usernameController,
            hint: 'Masukkan username atau email',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          // Password field
          _buildLabel('Password'),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 16),
          // Biometric toggle + forgot password
          Row(
            children: [
              _buildBiometricToggle(),
              const Spacer(),
              TextButton(
                onPressed: _showForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Lupa Password?',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Row(
            children: [
              const Expanded(
                  child: Divider(color: AppColors.surfaceVariant, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Expanded(
                  child: Divider(color: AppColors.surfaceVariant, height: 1)),
            ],
          ),
          const SizedBox(height: 16),
          // Biometric options
          Row(
            children: [
              Expanded(child: _buildBiometricOption(Icons.face, 'Scan Wajah')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildBiometricOption(
                      Icons.fingerprint, 'Sidik Jari')),
            ],
          ),
          const SizedBox(height: 16),
          // Login button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Masuk',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Belum memiliki akun Livin\'?',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Buka Rekening Baru',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.hankenGrotesk(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.hankenGrotesk(
            color: AppColors.outline.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        style: GoogleFonts.hankenGrotesk(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Masukkan password Anda',
          hintStyle: GoogleFonts.hankenGrotesk(
            color: AppColors.outline.withValues(alpha: 0.6),
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.outline),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.outline,
            ),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return GestureDetector(
      onTap: () => setState(() => _biometricEnabled = !_biometricEnabled),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _biometricEnabled
                  ? AppColors.onPrimaryContainer
                  : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _biometricEnabled
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Biometrik',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricOption(IconData icon, String label) {
    return GestureDetector(
      onTap: _isLoading ? null : _loginWithBiometric,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
