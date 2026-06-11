import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/bank_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'receipt_screen.dart';

class QrisConfirmScreen extends StatefulWidget {
  final QrisDraft draft;

  const QrisConfirmScreen({super.key, required this.draft});

  @override
  State<QrisConfirmScreen> createState() => _QrisConfirmScreenState();
}

class _QrisConfirmScreenState extends State<QrisConfirmScreen> {
  final List<bool> _pinFilled = List.filled(6, false);
  int _pinCount = 0;
  String _pinValue = '';
  bool _isProcessing = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

  Future<void> _confirmWithPin() async {
    if (_pinValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan PIN transaksi 6 digit.')),
      );
      return;
    }
    await _processPayment(pin: _pinValue);
  }

  Future<void> _confirmWithBiometric() async {
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'Konfirmasi pembayaran QRIS',
      );
      if (!authenticated) return;
      await _processPayment(useBiometric: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _processPayment({String? pin, bool useBiometric = false}) async {
    setState(() => _isProcessing = true);
    try {
      if (!useBiometric) {
        final pinValid = await BankService.verifyTransactionPin(pin!);
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
      }

      final transaction = await BankService.createQrisPayment(widget.draft);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            transaction: transaction,
            draft: TransferDraft(
              receiverAccountNumber: widget.draft.merchantCode,
              receiverBankName: 'QRIS',
              receiverName: widget.draft.merchantName,
              amount: widget.draft.amount,
              fee: 0,
              note: 'Pembayaran QRIS',
            ),
          ),
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
        title: Text(
          'Konfirmasi QRIS',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _formatter.format(widget.draft.amount),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.draft.merchantName,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pinFilled[index]
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _buildNumpad(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmWithPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isProcessing ? 'Memproses...' : 'Bayar Sekarang',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isProcessing ? null : _confirmWithBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Gunakan Biometrik'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return OutlinedButton(
          onPressed: () {
            if (key == 'del') {
              _removePin();
            } else {
              _addPin(key);
            }
          },
          child: key == 'del'
              ? const Icon(Icons.backspace_outlined)
              : Text(key, style: const TextStyle(fontSize: 20)),
        );
      },
    );
  }
}
