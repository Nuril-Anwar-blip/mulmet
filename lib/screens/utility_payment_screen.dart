import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class UtilityPaymentScreen extends StatefulWidget {
  final String type;
  final String title;
  final String idLabel;
  final String idHint;

  const UtilityPaymentScreen({
    super.key,
    required this.type,
    required this.title,
    required this.idLabel,
    required this.idHint,
  });

  @override
  State<UtilityPaymentScreen> createState() => _UtilityPaymentScreenState();
}

class _UtilityPaymentScreenState extends State<UtilityPaymentScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isPaying = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (_idController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data pembayaran.')),
      );
      return;
    }

    setState(() => _isPaying = true);
    try {
      await FeatureService.payUtility(
        type: widget.type,
        customerId: _idController.text.trim(),
        customerName: _nameController.text.trim(),
        amount: amount,
      );
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran ${widget.type} berhasil.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = SessionManager.currentAccount?.balance ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Saldo: ${_formatter.format(balance)}',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: widget.idLabel, hintText: widget.idHint)),
          const SizedBox(height: 12),
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Nominal', prefixText: 'Rp '),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [50000, 100000, 200000]
                .map((a) => ActionChip(
                      label: Text(_formatter.format(a)),
                      onPressed: () => _amountController.text =
                          NumberFormat('#,###', 'id_ID').format(a),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isPaying ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_isPaying ? 'Memproses...' : 'Bayar Sekarang',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
