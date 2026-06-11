import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';

class AccountSelectScreen extends StatefulWidget {
  const AccountSelectScreen({super.key});

  @override
  State<AccountSelectScreen> createState() => _AccountSelectScreenState();
}

class _AccountSelectScreenState extends State<AccountSelectScreen> {
  List<BankAccount> _accounts = [];
  String? _selectedAccountId;
  bool _isLoading = true;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedAccountId = SessionManager.currentAccount?.id;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final user = SessionManager.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final accounts = await BankService.getAccounts(user.id);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _maskAccount(String accountNumber) {
    if (accountNumber.length < 4) return accountNumber;
    return '**** ${accountNumber.substring(accountNumber.length - 4)}';
  }

  void _selectAccount(BankAccount account) {
    final user = SessionManager.currentUser;
    if (user == null) return;
    SessionManager.setSession(user, account);
    Navigator.pop(context, account);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Pilih Rekening',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final account = _accounts[index];
                final isSelected = account.id == _selectedAccountId;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _selectAccount(account),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.label,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${account.bankName} • ${_maskAccount(account.accountNumber)}',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatter.format(account.balance),
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
