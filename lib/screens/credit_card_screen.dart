import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/feature_models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  List<CreditCardAccount> _cards = [];
  bool _isLoading = true;
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final cards = await FeatureService.getCreditCards(user.id);
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  Future<void> _payCard(CreditCardAccount card, double amount) async {
    try {
      await FeatureService.payCreditCard(cardId: card.id, amount: amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran kartu kredit berhasil.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kartu Kredit',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.cardNumber,
                          style: GoogleFonts.hankenGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Text('Limit: ${_formatter.format(card.limit)}',
                          style: const TextStyle(color: Colors.white70)),
                      Text('Terpakai: ${_formatter.format(card.used)}',
                          style: const TextStyle(color: Colors.white70)),
                      Text('Tersedia: ${_formatter.format(card.available)}',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        'Min. bayar ${_formatter.format(card.minimumPayment)} • Jatuh tempo ${_dateFormatter.format(card.dueDate)}',
                        style: const TextStyle(
                            color: AppColors.onPrimaryContainer, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _payCard(card, card.minimumPayment),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white)),
                              child: const Text('Bayar Minimum'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _payCard(card, card.used),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary),
                              child: const Text('Lunas'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
