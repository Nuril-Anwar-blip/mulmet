import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/bank_service.dart';
import '../widgets/bottom_nav.dart';
import 'profile_screen.dart';
import 'transfer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  int? _expandedIndex;
  List<Transaction> _transactions = dummyTransactions;
  String _query = '';
  String _typeFilter = 'Semua Jenis';
  String _statusFilter = 'Semua Status';
  bool _isLoading = false;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((tx) {
      final query = _query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          tx.title.toLowerCase().contains(query) ||
          tx.subtitle.toLowerCase().contains(query) ||
          tx.id.toLowerCase().contains(query) ||
          (tx.recipientName?.toLowerCase().contains(query) ?? false) ||
          (tx.recipientAccount?.toLowerCase().contains(query) ?? false);
      final matchesType =
          _typeFilter == 'Semua Jenis' || tx.category == _typeFilter;
      final matchesStatus =
          _statusFilter == 'Semua Status' || tx.status == _statusFilter;
      return matchesQuery && matchesType && matchesStatus;
    }).toList();
  }

  Future<void> _loadTransactions() async {
    final account = SessionManager.currentAccount;
    if (account == null) return;

    setState(() => _isLoading = true);
    try {
      final transactions = await BankService.getTransactions(account.id);
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
          'Riwayat',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w700, color: AppColors.primary),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      hintStyle: GoogleFonts.hankenGrotesk(
                          color: AppColors.outlineVariant),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.outline),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('30 Hari Terakhir',
                          icon: Icons.calendar_today, isActive: true),
                      const SizedBox(width: 8),
                      _buildFilterChip(_typeFilter,
                          trailing: Icons.expand_more, onTap: _pickTypeFilter),
                      const SizedBox(width: 8),
                      _buildFilterChip(_statusFilter,
                          trailing: Icons.filter_list, onTap: _pickStatusFilter),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      if (_filteredTransactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(
                            child: Text(
                              'Tidak ada transaksi yang cocok.',
                              style: GoogleFonts.hankenGrotesk(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildMonthGroup('Transaksi Terbaru', _filteredTransactions),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TransferScreen()),
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

  Widget _buildFilterChip(String label,
      {IconData? icon,
      IconData? trailing,
      bool isActive = false,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing,
                  size: 16,
                  color: isActive ? Colors.white : AppColors.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTypeFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _FilterSheet(
        title: 'Jenis Transaksi',
        options: const ['Semua Jenis', 'Transfer', 'Pemasukan', 'Belanja', 'Tagihan'],
        selected: _typeFilter,
      ),
    );
    if (selected != null) setState(() => _typeFilter = selected);
  }

  Future<void> _pickStatusFilter() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _FilterSheet(
        title: 'Status',
        options: const ['Semua Status', 'Berhasil', 'Diproses', 'Gagal'],
        selected: _statusFilter,
      ),
    );
    if (selected != null) setState(() => _statusFilter = selected);
  }

  Widget _buildMonthGroup(String month, List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              month,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${transactions.length} Transaksi',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final tx = entry.value;
          final isExpanded = _expandedIndex == ('$month$index').hashCode;
          return _buildTxItem(tx, isExpanded, () {
            setState(() {
              _expandedIndex =
                  isExpanded ? null : ('$month$index').hashCode;
            });
          });
        }),
      ],
    );
  }

  Widget _buildTxItem(
      Transaction tx, bool isExpanded, VoidCallback onTap) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (tx.category) {
      case 'Transfer':
        icon = Icons.sync_alt;
        iconBg = AppColors.secondaryContainer;
        iconColor = AppColors.onSecondaryContainer;
        break;
      case 'Belanja':
        icon = Icons.shopping_bag_outlined;
        iconBg = AppColors.tertiaryFixed;
        iconColor = AppColors.onTertiaryFixedVariant;
        break;
      case 'Pemasukan':
        icon = Icons.account_balance_wallet_outlined;
        iconBg = AppColors.primaryFixed;
        iconColor = AppColors.primary;
        break;
      case 'Tagihan':
        icon = Icons.receipt_long_outlined;
        iconBg = AppColors.secondaryContainer;
        iconColor = AppColors.onSecondaryContainer;
        break;
      default:
        icon = Icons.payment;
        iconBg = AppColors.surfaceContainer;
        iconColor = AppColors.primary;
    }

    Widget statusBadge(String status) {
      Color bg, fg;
      if (status == 'Berhasil') {
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF059669);
      } else if (status == 'Diproses') {
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
      } else {
        bg = AppColors.errorContainer;
        fg = AppColors.error;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(status,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: iconBg),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title,
                          style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w700)),
                      Text(tx.subtitle,
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 12, color: AppColors.outline)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tx.isCredit ? '+' : '-'}${_formatter.format(tx.amount)}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tx.isCredit
                            ? const Color(0xFF059669)
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    statusBadge(tx.status),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _buildTxDetail(tx),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildTxDetail(Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (tx.recipientAccount != null)
            _buildDetailRow('Ke Rekening', tx.recipientAccount!),
          if (tx.recipientName != null)
            _buildDetailRow('Penerima', tx.recipientName!),
          _buildDetailRow('ID Transaksi', tx.id),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Resi ${tx.id} siap dibagikan dari halaman struk.')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Bagikan Resi',
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, color: AppColors.outline)),
          Text(value,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option),
                trailing: selected == option
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
