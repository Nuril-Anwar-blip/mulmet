import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final Transaction? transaction;
  final TransferDraft? draft;

  const ReceiptScreen({super.key, this.transaction, this.draft});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _cardController;
  late Animation<double> _checkScale;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Transaction get _transaction =>
      widget.transaction ??
      Transaction(
        id: 'TRF-9928172635',
        title: 'Transfer Keluar',
        subtitle: '12 Okt - 14:32',
        amount: 2500000,
        isCredit: false,
        date: '12 Okt',
        category: 'Transfer',
        recipientAccount: 'BCA - 8290012345',
      );

  TransferDraft get _draft =>
      widget.draft ??
      TransferDraft(
        receiverAccountNumber: '8290012345',
        receiverBankName: 'BCA',
        amount: _transaction.amount,
      );

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          ),
        ),
        title: Text(
          'Resi Transaksi',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Bank Mandiri',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // Success header
                  _buildSuccessHeader(),
                  const SizedBox(height: 24),
                  // Receipt card
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _buildReceiptCard(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Promo banner
                  FadeTransition(
                    opacity: _cardFade,
                    child: _buildPromoBanner(),
                  ),
                ],
              ),
            ),
          ),
          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0FDF4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF059669),
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Transfer Berhasil',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _transaction.subtitle,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 14, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGITAL RECEIPT',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_transaction.id}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_outlined,
                  size: 38,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          // Dashed divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    color: i.isEven ? AppColors.outlineVariant : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Amount box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Nominal',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.onSecondaryFixedVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatter.format(_transaction.amount),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Source
                _buildReceiptRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Sumber Dana',
                  name: 'Tabungan Mandiri',
                  detail: SessionManager.currentAccount?.accountNumber ?? '-',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                // Destination
                _buildReceiptRow(
                  icon: Icons.person_outline,
                  label: 'Penerima',
                  name: _transaction.recipientBank ?? _draft.receiverBankName,
                  detail: '${_draft.receiverBankName} - ${_draft.receiverAccountNumber}',
                ),
                const SizedBox(height: 20),
                // Fee rows
                _buildDetailLine(
                    'Nominal Transfer', _formatter.format(_transaction.amount)),
                const SizedBox(height: 8),
                _buildDetailLine('Biaya Admin', _formatter.format(_draft.fee)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Bayar',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                    Text(
                      _formatter.format(_transaction.amount + _draft.fee),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Simpan resi ini sebagai bukti transaksi yang sah.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          // Tear effect bottom
          ClipPath(
            clipper: _TearClipper(),
            child: Container(
              height: 20,
              color: AppColors.surfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow({
    required IconData icon,
    required String label,
    required String name,
    required String detail,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12, color: AppColors.secondary)),
            const SizedBox(height: 2),
            Text(name,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text(detail,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 13, color: AppColors.onSurfaceVariant)),
          ],
        ),
        Icon(icon, color: AppColors.secondary),
      ],
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 14, color: AppColors.secondary)),
        Text(value,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 14, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 88,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dapatkan Cashback',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 12, color: const Color(0xFF93C5FD)),
                ),
                Text(
                  'Hingga Rp 50.000',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Struk berhasil dibagikan')),
                );
              },
              icon: const Icon(Icons.share_outlined, size: 20),
              label: Text(
                'Bagikan Struk',
                style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const DashboardScreen()),
                (route) => false,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Kembali ke Beranda',
                style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TearClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    double x = 0;
    const step = 20.0;
    while (x < size.width) {
      path.arcToPoint(
        Offset(x + step, 0),
        radius: const Radius.circular(10),
        clockwise: false,
      );
      x += step;
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
