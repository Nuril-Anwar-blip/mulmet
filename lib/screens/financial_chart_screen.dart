import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/feature_models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class FinancialChartScreen extends StatefulWidget {
  const FinancialChartScreen({super.key});

  @override
  State<FinancialChartScreen> createState() => _FinancialChartScreenState();
}

class _FinancialChartScreenState extends State<FinancialChartScreen> {
  FinancialSummary? _summary;
  bool _isLoading = true;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = SessionManager.currentAccount;
    setState(() => _isLoading = true);
    final transactions =
        await BankService.getTransactions(account?.id ?? '');
    if (!mounted) return;
    setState(() {
      _summary = FeatureService.buildSummary(transactions);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grafik Keuangan',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('Data tidak tersedia.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummaryCard('Pemasukan',
                        _formatter.format(_summary!.totalIncome), AppColors.emerald),
                    const SizedBox(height: 10),
                    _buildSummaryCard('Pengeluaran',
                        _formatter.format(_summary!.totalExpense), AppColors.error),
                    const SizedBox(height: 10),
                    _buildSummaryCard(
                        'Arus Bersih',
                        _formatter.format(_summary!.netFlow),
                        _summary!.netFlow >= 0
                            ? AppColors.emerald
                            : AppColors.error),
                    const SizedBox(height: 24),
                    Text('Pengeluaran per Kategori',
                        style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: _summary!.expenseByCategory.isEmpty
                          ? Center(
                              child: Text('Belum ada data pengeluaran.',
                                  style: GoogleFonts.hankenGrotesk(
                                      color: AppColors.secondary)),
                            )
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _summary!.expenseByCategory.entries
                                    .map((e) {
                                  final colors = [
                                    AppColors.primary,
                                    AppColors.tertiaryContainer,
                                    AppColors.secondary,
                                    AppColors.emerald,
                                    AppColors.amber,
                                  ];
                                  final i = _summary!.expenseByCategory.keys
                                      .toList()
                                      .indexOf(e.key);
                                  return PieChartSectionData(
                                    value: e.value,
                                    title: e.key,
                                    color: colors[i % colors.length],
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w600, color: AppColors.secondary)),
          Text(value,
              style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
