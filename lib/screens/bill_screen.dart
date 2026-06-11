import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/bank_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'transfer_screen.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController(text: 'Tagihan Pembayaran');
  final _amountController = TextEditingController();
  final _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  List<BillInvoice> _bills = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    final user = SessionManager.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final bills = await BankService.getBills(user.id);
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (amount <= 0) {
      _showMessage('Nominal tagihan harus lebih dari Rp 0.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bill = await BankService.createBill(
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        title: _titleController.text,
        amount: amount,
      );
      if (!mounted) return;
      setState(() {
        _bills = [bill, ..._bills];
        _isSaving = false;
      });
      _nameController.clear();
      _emailController.clear();
      _amountController.clear();
      _showMessage('Tagihan berhasil disimpan.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setAmount(int amount) {
    setState(() {
      _amountController.text = NumberFormat('#,###', 'id_ID').format(amount);
    });
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Lunas';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return 'Belum Dibayar';
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
          'Tagihan',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBills,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            _buildFormCard(),
            const SizedBox(height: 28),
            _buildBillList(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TransferScreen()),
            );
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

  Widget _buildFormCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUAT TAGIHAN BARU',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Penerima Tagihan',
                  hint: 'Contoh: Budi Santoso',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Penerima',
                  hint: 'nama@email.com',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email wajib diisi.';
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Format email tidak valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleController,
                  label: 'Nama Tagihan',
                  hint: 'Contoh: Tagihan Internet Juni',
                  icon: Icons.receipt_long_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tagihan wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _amountController,
                  label: 'Nominal',
                  hint: '0',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final amount = double.tryParse(
                          (value ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    if (amount <= 0) return 'Nominal wajib diisi.';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50000, 100000, 250000, 500000].map((amount) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(_currencyFormatter.format(amount)),
                          onPressed: () => _setAmount(amount),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveBill,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Tagihan',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.hankenGrotesk(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildBillList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tagihan Tersimpan',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${_bills.length} Data',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_bills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Belum ada tagihan. Buat tagihan pertama dengan nama dan email penerima.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(color: AppColors.secondary),
            ),
          )
        else
          ..._bills.map(_buildBillItem),
      ],
    );
  }

  Widget _buildBillItem(BillInvoice bill) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryContainer,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bill.customerName,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  bill.customerEmail,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _dateFormatter.format(bill.createdAt),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormatter.format(bill.amount),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(bill.status),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
