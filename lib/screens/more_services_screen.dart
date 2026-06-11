import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'bill_screen.dart';
import 'credit_card_screen.dart';
import 'deposito_screen.dart';
import 'favorites_screen.dart';
import 'financial_chart_screen.dart';
import 'history_screen.dart';
import 'login_history_screen.dart';
import 'my_qris_screen.dart';
import 'qris_screen.dart';
import 'scheduled_transfer_screen.dart';
import 'transfer_screen.dart';
import 'utility_payment_screen.dart';

class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.sync_alt, 'title': AppStrings.t('transfer'), 'screen': const TransferScreen()},
      {'icon': Icons.qr_code_scanner, 'title': AppStrings.t('qris'), 'screen': const QrisScreen()},
      {'icon': Icons.qr_code_2, 'title': AppStrings.t('my_qris'), 'screen': const MyQrisScreen()},
      {'icon': Icons.receipt_long_outlined, 'title': 'Tagihan', 'screen': const BillScreen()},
      {'icon': Icons.electric_bolt_outlined, 'title': AppStrings.t('pln'), 'screen': const UtilityPaymentScreen(type: 'PLN', title: 'Bayar PLN', idLabel: 'ID Pelanggan / No. Meter', idHint: '12345678901')},
      {'icon': Icons.phone_android_outlined, 'title': AppStrings.t('pulsa'), 'screen': const UtilityPaymentScreen(type: 'Pulsa', title: 'Pulsa & Data', idLabel: 'Nomor HP', idHint: '08123456789')},
      {'icon': Icons.savings_outlined, 'title': AppStrings.t('deposito'), 'screen': const DepositoScreen()},
      {'icon': Icons.credit_card_outlined, 'title': AppStrings.t('credit_card'), 'screen': const CreditCardScreen()},
      {'icon': Icons.schedule, 'title': AppStrings.t('scheduled_transfer'), 'screen': const ScheduledTransferScreen()},
      {'icon': Icons.star_outline, 'title': AppStrings.t('favorites'), 'screen': const FavoritesScreen()},
      {'icon': Icons.bar_chart, 'title': AppStrings.t('financial_chart'), 'screen': const FinancialChartScreen()},
      {'icon': Icons.history, 'title': AppStrings.t('history'), 'screen': const HistoryScreen()},
      {'icon': Icons.devices, 'title': AppStrings.t('login_history'), 'screen': const LoginHistoryScreen()},
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          AppStrings.t('more_services'),
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => service['screen'] as Widget,
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      service['title'] as String,
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
