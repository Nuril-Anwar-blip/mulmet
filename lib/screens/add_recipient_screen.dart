import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'confirm_transaction_screen.dart';

class AddRecipientScreen extends StatefulWidget {
  const AddRecipientScreen({super.key});

  @override
  State<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends State<AddRecipientScreen>
    with SingleTickerProviderStateMixin {
  final _accountController = TextEditingController();
  bool _isVerifyEnabled = false;
  bool _isVerifying = false;
  bool _isVerified = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _recentRecipients = [
    {
      'name': 'Amanda Sitorus',
      'bank': 'Mandiri',
      'account': '124 000 9821',
      'initials': 'AS',
      'color': AppColors.secondaryContainer,
    },
    {
      'name': 'Budi Darmawan',
      'bank': 'Mandiri',
      'account': '130 112 0045',
      'initials': 'BD',
      'color': AppColors.surfaceContainerHighest,
    },
    {
      'name': 'Kevin Sanjaya',
      'bank': 'Mandiri',
      'account': '111 000 7732',
      'initials': 'KS',
      'color': AppColors.tertiaryFixed,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onAccountChanged(String value) {
    setState(() {
      _isVerifyEnabled = value.length >= 8;
      _isVerified = false;
    });
  }

  Future<void> _verifyAccount() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isVerified = true;
      });
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
          'Tambah Penerima',
          style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank selection status card
            FadeTransition(
              opacity: _fadeAnim,
              child: _buildBankCard(),
            ),
            const SizedBox(height: 28),
            // Account number input section
            _buildAccountInput(),
            const SizedBox(height: 28),
            // Recent recipients
            _buildRecentSection(),
            const SizedBox(height: 20),
            // Security badge
            _buildSecurityBadge(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavNoQris(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildBankCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance,
                  color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Tujuan',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
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
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Text(
              'Ubah',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.primaryFixedDim,
              ),
            ),
            label: const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.primaryFixedDim),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nomor Rekening',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Input field
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accountController,
                  onChanged: _onAccountChanged,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nomor rekening',
                    hintStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.outlineVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              if (_isVerified)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Color(0xFF059669), size: 18),
                  ),
                )
              else if (_isVerifyEnabled)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.outline.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Verified account name (shown after verify)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _isVerified
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budi Pratama',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Mandiri • Tabungan',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
          crossFadeState: _isVerified
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
        const SizedBox(height: 12),
        // Verify button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isVerifyEnabled && !_isVerifying && !_isVerified
                ? _verifyAccount
                : _isVerified
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ConfirmTransactionScreen()),
                        )
                    : null,
            icon: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(
                    _isVerified ? Icons.arrow_forward : Icons.verified_outlined,
                    size: 20),
            label: Text(
              _isVerifying
                  ? 'Memverifikasi...'
                  : _isVerified
                      ? 'Lanjut Transfer'
                      : 'Verifikasi',
              style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isVerified ? const Color(0xFF059669) : AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekening Terakhir',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Lihat Semua',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryFixedDim),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Grid of recent recipients
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentRecipients.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 10,
            childAspectRatio: 4.5,
          ),
          itemBuilder: (context, i) {
            final r = _recentRecipients[i];
            return GestureDetector(
              onTap: () {
                _accountController.text = r['account'];
                setState(() {
                  _isVerifyEnabled = true;
                  _isVerified = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isVerified &&
                            _accountController.text == r['account']
                        ? AppColors.primaryFixed
                        : Colors.transparent,
                    width: 1.5,
                  ),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: r['color'] as Color,
                      ),
                      child: Center(
                        child: Text(
                          r['initials'],
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r['name'],
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${r['bank']} • ${r['account']}',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.outlineVariant),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: Color(0xFF059669), size: 15),
        const SizedBox(width: 6),
        Text(
          'Transaksi aman & terenkripsi oleh Bank Mandiri',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
