import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/bank_service.dart';
import '../theme/app_theme.dart';

class MyQrisScreen extends StatelessWidget {
  const MyQrisScreen({super.key});

  String _buildPayload() {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    if (user == null || account == null) return 'MANDIRI-QRIS';

    // Simplified QR payload for receiving payments
    return 'QRIS|${user.fullName}|${account.accountNumber}|Mandiri';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    final payload = _buildPayload();

    return Scaffold(
      appBar: AppBar(
        title: Text('QRIS Saya',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20),
                  ],
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user?.fullName ?? 'Nasabah',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mandiri • ${account?.accountNumber ?? '-'}',
                style: GoogleFonts.hankenGrotesk(color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                'Tunjukkan QR ini untuk menerima pembayaran.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
