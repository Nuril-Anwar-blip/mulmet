import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordConfirmScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.token;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sama.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await FeatureService.resetPasswordWithToken(
        email: widget.email,
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diperbarui.')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Kode Reset'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Konfirmasi Password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                    _isSubmitting ? 'Menyimpan...' : 'Simpan Password Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
