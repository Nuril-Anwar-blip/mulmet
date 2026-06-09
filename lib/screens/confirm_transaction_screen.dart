import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import 'receipt_screen.dart';

class ConfirmTransactionScreen extends StatefulWidget {
  final TransferDraft? draft;

  const ConfirmTransactionScreen({super.key, this.draft});

  @override
  State<ConfirmTransactionScreen> createState() =>
      _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState extends State<ConfirmTransactionScreen> {
  final List<bool> _pinFilled = List.filled(6, false);
  int _pinCount = 0;
  String _pinValue = '';
  bool _isProcessing = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  TransferDraft get _draft =>
      widget.draft ??
      TransferDraft(
        receiverAccountNumber: '8290012345',
        receiverBankName: 'BCA',
        amount: 2500000,
      );

  void _addPin(String digit) {
    if (_pinCount < 6) {
      setState(() {
        _pinValue += digit;
        _pinFilled[_pinCount] = true;
        _pinCount++;
      });
    }
  }

  void _removePin() {
    if (_pinCount > 0) {
      setState(() {
        _pinCount--;
        _pinValue = _pinValue.substring(0, _pinValue.length - 1);
        _pinFilled[_pinCount] = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_pinValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan PIN transaksi 6 digit.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final pinValid = await BankService.verifyTransactionPin(_pinValue);
      if (!pinValid) {
        if (!mounted) return;
        setState(() {
          _pinValue = '';
          _pinCount = 0;
          for (var i = 0; i < _pinFilled.length; i++) {
            _pinFilled[i] = false;
          }
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN transaksi salah.')),
        );
        return;
      }

      final transaction = await BankService.createTransfer(_draft);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transaction: transaction, draft: _draft),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
          'Konfirmasi',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi belum tersedia untuk mode demo.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          children: [
            // Amount header
            Text(
              'Jumlah Transfer',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatter.format(_draft.amount),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            // Source card
            _buildAccountCard(
              label: 'Dari Rekening',
              name: 'Tabungan Mandiri',
              detail: SessionManager.currentAccount?.accountNumber ?? '-',
              icon: Icons.account_balance_wallet_outlined,
              iconBg: AppColors.primaryFixed,
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.south,
                    color: AppColors.primary, size: 18),
              ),
            ),
            // Destination card
            _buildAccountCard(
              label: 'Ke Rekening',
              name: _draft.receiverName ?? 'Penerima',
              detail: '${_draft.receiverBankName} - ${_draft.receiverAccountNumber}',
              icon: Icons.person_outline,
              iconBg: AppColors.secondaryFixed,
            ),
            const SizedBox(height: 20),
            // Fee breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildFeeRow('Biaya Admin', _formatter.format(_draft.fee)),
                  const SizedBox(height: 8),
                  _buildFeeRow('Metode', 'BI-FAST'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: DashedDivider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Bayar',
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _formatter.format(_draft.amount + _draft.fee),
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Biometric button
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Biometrik belum tersedia. Gunakan PIN transaksi.'),
                  ),
                );
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.secondary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: AppColors.onSecondaryContainer,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sentuh untuk verifikasi biometrik',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // OR divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ATAU MASUKKAN PIN',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: AppColors.outline,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _pinFilled.map((filled) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: 2,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Number pad
            _buildNumberPad(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isProcessing || _pinValue.length != 6
                ? null
                : _confirmPayment,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.verified_user_outlined, size: 20),
            label: Text(
              _isProcessing ? 'Memproses...' : 'Konfirmasi & Bayar',
              style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required String label,
    required String name,
    required String detail,
    required IconData icon,
    required Color iconBg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, color: AppColors.onPrimaryFixed, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(detail,
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 13, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.hankenGrotesk(fontSize: 14, color: AppColors.onSurfaceVariant)),
        Text(value,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        ...List.generate(9, (i) {
          final digit = '${i + 1}';
          return _pinButton(digit, () => _addPin(digit));
        }),
        _pinButton('', () {}),
        _pinButton('0', () => _addPin('0')),
        _pinButton('⌫', () => _removePin(), isBack: true),
      ],
    );
  }

  Widget _pinButton(String label, VoidCallback onTap, {bool isBack = false}) {
    if (label.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isBack ? AppColors.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
