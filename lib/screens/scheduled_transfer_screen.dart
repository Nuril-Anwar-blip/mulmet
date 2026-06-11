import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/feature_models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class ScheduledTransferScreen extends StatefulWidget {
  const ScheduledTransferScreen({super.key});

  @override
  State<ScheduledTransferScreen> createState() =>
      _ScheduledTransferScreenState();
}

class _ScheduledTransferScreenState extends State<ScheduledTransferScreen> {
  List<ScheduledTransfer> _scheduled = [];
  bool _isLoading = true;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  String _bank = 'Mandiri';
  String _frequency = 'Bulanan';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final list = await FeatureService.getScheduledTransfers(user.id);
    if (!mounted) return;
    setState(() {
      _scheduled = list;
      _isLoading = false;
    });
  }

  Future<void> _create() async {
    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (_nameController.text.isEmpty ||
        _accountController.text.isEmpty ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data transfer terjadwal.')),
      );
      return;
    }

    await FeatureService.createScheduledTransfer(
      receiverAccountNumber: _accountController.text.trim(),
      receiverBankName: _bank,
      receiverName: _nameController.text.trim(),
      amount: amount,
      frequency: _frequency,
      nextRunDate: DateTime.now().add(const Duration(days: 1)),
    );
    _nameController.clear();
    _accountController.clear();
    _amountController.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Terjadwal',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Jadwalkan Transfer',
                    style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nama Penerima')),
                TextField(
                    controller: _accountController,
                    decoration:
                        const InputDecoration(labelText: 'No. Rekening')),
                TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Nominal', prefixText: 'Rp ')),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration:
                      const InputDecoration(labelText: 'Frekuensi'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Harian', child: Text('Harian')),
                    DropdownMenuItem(
                        value: 'Mingguan', child: Text('Mingguan')),
                    DropdownMenuItem(
                        value: 'Bulanan', child: Text('Bulanan')),
                  ],
                  onChanged: (v) => setState(() => _frequency = v ?? 'Bulanan'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _create,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: const Text('Simpan Jadwal'),
                ),
                const SizedBox(height: 24),
                Text('Jadwal Aktif',
                    style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                if (_scheduled.isEmpty)
                  Text('Belum ada jadwal.',
                      style: GoogleFonts.hankenGrotesk(
                          color: AppColors.secondary))
                else
                  ..._scheduled.map((s) => Card(
                        child: ListTile(
                          title: Text(s.receiverName),
                          subtitle: Text(
                            '${s.receiverBankName} ${s.receiverAccountNumber}\n${_formatter.format(s.amount)} • ${s.frequency} • ${_dateFormatter.format(s.nextRunDate)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              await FeatureService.deleteScheduledTransfer(
                                  s.id);
                              await _load();
                            },
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
