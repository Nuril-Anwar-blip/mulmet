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
  final _compactFormatter =
      NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ');

  static const _categoryColors = [
    Color(0xFF001831),
    Color(0xFF0F766E),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = SessionManager.currentAccount;
    setState(() => _isLoading = true);
    final transactions = await BankService.getTransactions(account?.id ?? '');
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
                    _buildSummaryCard(
                      'Pemasukan',
                      _formatter.format(_summary!.totalIncome),
                      AppColors.emerald,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard(
                      'Pengeluaran',
                      _formatter.format(_summary!.totalExpense),
                      AppColors.error,
                    ),
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
                    _buildExpenseChart(),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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

  Widget _buildExpenseChart() {
    final entries = _summary!.expenseByCategory.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense = entries.fold<double>(0, (sum, e) => sum + e.value);

    if (entries.isEmpty || totalExpense <= 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'Belum ada data pengeluaran.',
          style: GoogleFonts.hankenGrotesk(color: AppColors.secondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: entries.length == 1 ? 0 : 3,
                    centerSpaceRadius: 54,
                    startDegreeOffset: -90,
                    sections: [
                      for (var i = 0; i < entries.length; i++)
                        PieChartSectionData(
                          value: entries[i].value,
                          title: '',
                          color: _categoryColors[i % _categoryColors.length],
                          radius: 34,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _compactFormatter.format(totalExpense),
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...[
            for (var i = 0; i < entries.length; i++)
              _buildCategoryRow(
                entries[i].key,
                entries[i].value,
                totalExpense,
                _categoryColors[i % _categoryColors.length],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String label,
    double value,
    double total,
    Color color,
  ) {
    final percentage = total == 0 ? 0 : (value / total * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$percentage%',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _formatter.format(value),
                style: GoogleFonts.hankenGrotesk(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
