import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/otp_service.dart';
import '../theme/app_theme.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String userId;
  final String otpCode;
  final VoidCallback onVerified;

  const OtpVerifyScreen({
    super.key,
    required this.userId,
    required this.otpCode,
    required this.onVerified,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final valid =
        await OtpService.verifyOtp(widget.userId, _controller.text.trim());
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP salah atau kedaluwarsa.')),
      );
      return;
    }

    await OtpService.clearOtp(widget.userId);
    widget.onVerified();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi OTP',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kode OTP 6 digit. Untuk demo, kode Anda:',
              style: GoogleFonts.hankenGrotesk(color: AppColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.otpCode,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isVerifying ? 'Memverifikasi...' : 'Verifikasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
