import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/feature_models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class DepositoScreen extends StatefulWidget {
  const DepositoScreen({super.key});

  @override
  State<DepositoScreen> createState() => _DepositoScreenState();
}

class _DepositoScreenState extends State<DepositoScreen> {
  final _amountController = TextEditingController(text: '5000000');
  int _termMonths = 6;
  double _interestRate = 5.5;
  List<DepositAccount> _deposits = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final deposits = await FeatureService.getDeposits(user.id);
    if (!mounted) return;
    setState(() {
      _deposits = deposits;
      _isLoading = false;
    });
  }

  Future<void> _openDeposit() async {
    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    setState(() => _isSaving = true);
    try {
      await FeatureService.createDeposit(
        amount: amount,
        termMonths: _termMonths,
        interestRate: _interestRate,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deposito berhasil dibuka.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deposito',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Buka Deposito Baru',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nominal', prefixText: 'Rp '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _termMonths,
                  decoration: const InputDecoration(labelText: 'Jangka Waktu'),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 Bulan')),
                    DropdownMenuItem(value: 6, child: Text('6 Bulan')),
                    DropdownMenuItem(value: 12, child: Text('12 Bulan')),
                  ],
                  onChanged: (v) => setState(() => _termMonths = v ?? 6),
                ),
                const SizedBox(height: 12),
                Text('Bunga: $_interestRate% per tahun',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.secondary)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _openDeposit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white),
                    child: Text(_isSaving ? 'Memproses...' : 'Buka Deposito'),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Deposito Aktif',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (_deposits.isEmpty)
                  Text('Belum ada deposito aktif.',
                      style: GoogleFonts.hankenGrotesk(
                          color: AppColors.secondary))
                else
                  ..._deposits.map((d) => Card(
                        child: ListTile(
                          title: Text(_formatter.format(d.amount),
                              style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${d.termMonths} bln • Jatuh tempo ${_dateFormatter.format(d.maturityDate)}\nEstimasi bunga: ${_formatter.format(d.projectedReturn)}',
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
