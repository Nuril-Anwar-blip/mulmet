import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class BankSelectScreen extends StatefulWidget {
  const BankSelectScreen({super.key});

  @override
  State<BankSelectScreen> createState() => _BankSelectScreenState();
}

class _BankSelectScreenState extends State<BankSelectScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  List<Bank> get _filteredBanks => allBanks
      .where(
          (b) => b.name.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  Map<String, List<Bank>> get _groupedBanks {
    final filtered = _filteredBanks;
    final Map<String, List<Bank>> groups = {};
    for (var bank in filtered) {
      final key = bank.name[0].toUpperCase();
      groups.putIfAbsent(key, () => []).add(bank);
    }
    final sorted = Map.fromEntries(
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sorted;
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
          'Pilih Bank Tujuan',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pilih bank tujuan, lalu masukkan nomor rekening yang ada di database.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama bank atau kode bank...',
                  hintStyle: GoogleFonts.hankenGrotesk(
                      color: AppColors.outlineVariant),
                  prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Popular banks
                Text(
                  'Bank Populer',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                      letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: popularBanks.map((bank) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, bank.name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                              ),
                              child: Center(
                                child: Text(
                                  bank.name.substring(0, 1),
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bank.name,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Semua Bank',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                      letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),
                ..._groupedBanks.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          entry.key,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          children: entry.value.asMap().entries.map((e) {
                            final isLast =
                                e.key == entry.value.length - 1;
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    e.value.name,
                                    style: GoogleFonts.hankenGrotesk(
                                        fontSize: 15),
                                  ),
                                  trailing: const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.outlineVariant),
                                  onTap: () =>
                                      Navigator.pop(context, e.value.name),
                                ),
                                if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
