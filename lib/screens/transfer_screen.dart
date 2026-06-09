import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'bank_select_screen.dart';
import 'confirm_transaction_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _accountController = TextEditingController();
  final _nominalController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedBank = 'Mandiri';
  BankAccount? _account = SessionManager.currentAccount;
  List<FavoriteRecipient> _favoriteRecipients = [];
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _favorites = [
    {'name': 'Siska', 'initials': 'SK', 'color': AppColors.secondaryContainer},
    {'name': 'Ahmad', 'initials': 'AM', 'color': AppColors.tertiaryFixed},
    {'name': 'Rian', 'initials': 'RN', 'color': AppColors.primaryFixed},
    {'name': 'PLN', 'initials': null, 'icon': Icons.corporate_fare, 'color': AppColors.surfaceContainerHighest},
  ];

  final List<int> _quickAmounts = [50000, 100000, 500000, 1000000];

  List<Map<String, dynamic>> get _favoriteItems {
    if (_favoriteRecipients.isEmpty) return _favorites;
    return _favoriteRecipients
        .map((favorite) => {
              'name': favorite.name,
              'initials': favorite.name.length >= 2
                  ? favorite.name.substring(0, 2).toUpperCase()
                  : favorite.name.toUpperCase(),
              'color': AppColors.secondaryContainer,
              'accountNumber': favorite.accountNumber,
              'bankName': favorite.bankName,
            })
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTransferData();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _nominalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setNominal(int amount) {
    setState(() {
      _nominalController.text =
          NumberFormat('#,###', 'id_ID').format(amount);
    });
  }

  Future<void> _loadTransferData() async {
    final user = SessionManager.currentUser;
    if (user == null) return;

    try {
      final account = await BankService.getPrimaryAccount(user.id);
      final favorites = await BankService.getFavorites(user.id);
      if (!mounted) return;
      setState(() {
        _account = account;
        _favoriteRecipients = favorites;
      });
    } catch (_) {}
  }

  void _continueToConfirmation() {
    final amount =
        double.tryParse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
    if (_accountController.text.trim().isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi rekening tujuan dan nominal.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmTransactionScreen(
          draft: TransferDraft(
            receiverAccountNumber: _accountController.text.trim(),
            receiverBankName: _selectedBank,
            amount: amount,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
        ),
      ),
    );
  }

  String _maskAccount(String? accountNumber) {
    if (accountNumber == null || accountNumber.length < 4) return '****';
    return '**** ${accountNumber.substring(accountNumber.length - 4)}';
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
          'Transfer Dana',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source account card
            _buildSourceCard(),
            const SizedBox(height: 28),
            // Favorites
            _buildFavorites(),
            const SizedBox(height: 28),
            // Transfer destination form
            _buildDestinationForm(),
            const SizedBox(height: 28),
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
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

  Widget _buildSourceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUMBER DANA',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tabungan Mandiri',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                          _maskAccount(_account?.accountNumber),
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 2),
                          ),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.onPrimaryContainer),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Saldo Tersedia',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatter.format(_account?.balance ?? 0),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: Text(
                          'Ganti Rekening',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13, color: AppColors.onPrimaryContainer),
                        ),
                        label: const Icon(Icons.expand_more,
                            size: 16, color: AppColors.onPrimaryContainer),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAFTAR FAVORIT',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                  letterSpacing: 0.5),
            ),
            Text(
              'Lihat Semua',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // New transfer
              Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1.5,
                          style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text('Baru',
                      style: GoogleFonts.hankenGrotesk(fontSize: 12)),
                ],
              ),
              const SizedBox(width: 16),
              ..._favoriteItems.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      if (f['accountNumber'] != null) {
                        setState(() {
                          _accountController.text =
                              f['accountNumber'] as String;
                          _selectedBank = f['bankName'] as String;
                        });
                      }
                    },
                    child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: f['color'] as Color,
                        ),
                        child: f['initials'] != null
                            ? Center(
                                child: Text(
                                  f['initials'] as String,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Icon(f['icon'] as IconData,
                                color: AppColors.secondary),
                      ),
                      const SizedBox(height: 6),
                      Text(f['name'] as String,
                          style: GoogleFonts.hankenGrotesk(fontSize: 12)),
                    ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TUJUAN TRANSFER',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        // Bank selector
        _buildFormLabel('Bank Tujuan'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankSelectScreen()),
            );
            if (result != null) setState(() => _selectedBank = result);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_outlined,
                    color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBank,
                    style: GoogleFonts.hankenGrotesk(fontSize: 16),
                  ),
                ),
                const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFormLabel('Nomor Rekening'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _accountController,
          hint: 'Masukkan nomor rekening',
          prefixIcon: Icons.dialpad,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildFormLabel('Nominal'),
        const SizedBox(height: 6),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Text(
                'Rp',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.hankenGrotesk(
                        color: AppColors.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickAmounts.map((amount) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _setNominal(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      amount >= 1000000
                          ? 'Rp ${(amount / 1000000).toStringAsFixed(0)}jt'
                          : _formatter.format(amount),
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildFormLabel('Catatan (Opsional)'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _noteController,
          hint: 'Berikan keterangan transfer',
          prefixIcon: Icons.notes_outlined,
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.hankenGrotesk(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.hankenGrotesk(color: AppColors.outlineVariant),
          prefixIcon:
              Icon(prefixIcon, color: AppColors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _continueToConfirmation,
            icon: const SizedBox.shrink(),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjut Ke Konfirmasi',
                  style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pastikan data tujuan sudah benar sebelum melanjutkan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 12, color: AppColors.secondary),
        ),
      ],
    );
  }
}
