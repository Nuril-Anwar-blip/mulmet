import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'qris_confirm_screen.dart';
import 'qris_scanner_screen.dart';
import 'transfer_screen.dart';
import '../utils/qris_parser.dart';

class QrisScreen extends StatefulWidget {
  const QrisScreen({super.key});

  @override
  State<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends State<QrisScreen> {
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  BankAccount? _account = SessionManager.currentAccount;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _merchants = [
    {'name': 'Indomaret Point', 'code': 'IDM-001'},
    {'name': 'Alfamart', 'code': 'ALF-002'},
    {'name': 'Starbucks Reserve', 'code': 'SBX-003'},
    {'name': 'KFC Drive Thru', 'code': 'KFC-004'},
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    setState(() {
      _amountController.text = NumberFormat('#,###', 'id_ID').format(amount);
    });
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<QrisData>(
      context,
      MaterialPageRoute(builder: (_) => const QrisScannerScreen()),
    );
    if (result == null || !mounted) return;

    setState(() {
      _merchantController.text = result.merchantName;
      if (result.amount != null && result.amount! > 0) {
        _amountController.text =
            NumberFormat('#,###', 'id_ID').format(result.amount);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QRIS terbaca: ${result.merchantName}'),
      ),
    );
  }

  Future<void> _continuePayment() async {
    final merchant = _merchantController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;

    if (merchant.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi merchant dan nominal pembayaran.')),
      );
      return;
    }

    if ((_account?.balance ?? 0) < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo tidak cukup untuk pembayaran QRIS.')),
      );
      return;
    }

    final draft = QrisDraft(
      merchantName: merchant,
      merchantCode: merchant.toUpperCase().replaceAll(' ', '-'),
      amount: amount,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrisConfirmScreen(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Bayar QRIS',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _openScanner,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          size: 96, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ketuk untuk scan QRIS',
                      style: GoogleFonts.hankenGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saldo: ${_formatter.format(_account?.balance ?? 0)}',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  'Buka Kamera Scan',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MERCHANT',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                hintText: 'Nama merchant',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _merchants.map((merchant) {
                return ActionChip(
                  label: Text(merchant['name'] as String),
                  onPressed: () {
                    _merchantController.text = merchant['name'] as String;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'NOMINAL',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Rp 0',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [25000, 50000, 100000]
                  .map((amount) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => _setAmount(amount),
                          child: Text(_formatter.format(amount)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _continuePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Lanjut Pembayaran',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
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
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
