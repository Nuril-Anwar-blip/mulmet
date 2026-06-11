import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/bank_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/notification_icon_button.dart';
import 'bill_screen.dart';
import 'transfer_screen.dart';
import 'history_screen.dart';
import 'financial_chart_screen.dart';
import 'more_services_screen.dart';
import 'profile_screen.dart';
import 'qris_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _balanceHidden = false;
  AppUser? _user = SessionManager.currentUser;
  BankAccount? _account = SessionManager.currentAccount;
  List<Transaction> _transactions = [];
  final _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late AnimationController _animController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sectionAnimations = List.generate(
      5,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, 0.6 + i * 0.1, curve: Curves.easeOut),
        ),
      ),
    );
    _animController.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TransferScreen()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const QrisScreen()));
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    } else if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _openBillScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BillScreen()),
    );
    if (!mounted) return;
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    if (user == null) return;

    try {
      final latestAccount = await BankService.getPrimaryAccount(user.id);
      final transactions = latestAccount == null
          ? <Transaction>[]
          : await BankService.getTransactions(latestAccount.id);
      if (!mounted) return;
      if (latestAccount != null) {
        SessionManager.setSession(user, latestAccount);
      }
      setState(() {
        _user = user;
        _account = latestAccount;
        _transactions = transactions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _account = account;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimated(0, _buildBalanceCard()),
                const SizedBox(height: 28),
                _buildAnimated(1, _buildQuickActions()),
                const SizedBox(height: 28),
                _buildAnimated(2, _buildFinancialSummaryCard()),
                const SizedBox(height: 28),
                _buildAnimated(2, _buildPromoBanner()),
                const SizedBox(height: 28),
                _buildAnimated(3, _buildTransactionsSection()),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_sectionAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 6),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.primaryContainer, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Halo,',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _user?.fullName.split(' ').first ?? 'Nasabah',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const NotificationIconButton(),
              const SizedBox(width: 12),
              Text(
                'Bank Mandiri',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      toolbarHeight: 86,
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative blob
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Saldo Anda',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _balanceHidden
                                  ? 'Rp ••••••••'
                                  : _currencyFormatter
                                      .format(_account?.balance ?? 0),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _balanceHidden = !_balanceHidden),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  _balanceHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'VISA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_account?.bankName ?? 'Mandiri'} Utama - ${_account?.accountNumber ?? ''}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.sync_alt,
        'label': 'Transfer',
        'color': AppColors.secondaryContainer,
        'iconColor': AppColors.primary
      },
      {
        'icon': Icons.qr_code_scanner,
        'label': 'QRIS',
        'color': AppColors.tertiaryFixed,
        'iconColor': AppColors.tertiaryContainer
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'Tagihan',
        'color': AppColors.primaryFixed,
        'iconColor': AppColors.primary
      },
      {
        'icon': Icons.grid_view,
        'label': 'Lainnya',
        'color': AppColors.surfaceContainerHigh,
        'iconColor': AppColors.onSurfaceVariant
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () {
            if (a['label'] == 'Transfer') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransferScreen()));
            } else if (a['label'] == 'Tagihan') {
              _openBillScreen();
            } else if (a['label'] == 'QRIS') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QrisScreen()));
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoreServicesScreen()),
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: a['color'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(a['icon'] as IconData,
                    color: a['iconColor'] as Color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                a['label'] as String,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialSummaryCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinancialChartScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
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
              child: const Icon(Icons.bar_chart, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grafik Keuangan',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Lihat ringkasan pemasukan & pengeluaran',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
        ),
      ),
      child: Stack(
        children: [
          // Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Terbatas',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiaryFixed,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cashback hingga 50%\ndi merchant pilihan.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terakhir',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._transactions.take(3).map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (tx.category) {
      case 'Belanja':
        icon = Icons.shopping_cart_outlined;
        iconBg = AppColors.surfaceContainer;
        iconColor = AppColors.primary;
        break;
      case 'Pemasukan':
        icon = Icons.account_balance_wallet_outlined;
        iconBg = const Color(0xFFD1FAE5);
        iconColor = const Color(0xFF059669);
        break;
      case 'Hiburan':
        icon = Icons.coffee_outlined;
        iconBg = AppColors.surfaceContainer;
        iconColor = AppColors.primary;
        break;
      default:
        icon = Icons.receipt_long_outlined;
        iconBg = AppColors.surfaceContainer;
        iconColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  tx.subtitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'}${_currencyFormatter.format(tx.amount)}',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color:
                  tx.isCredit ? const Color(0xFF059669) : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
