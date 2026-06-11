import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/feature_models.dart';
import '../services/bank_service.dart';
import '../services/feature_service.dart';
import '../theme/app_theme.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  List<LoginHistoryEntry> _entries = [];
  bool _isLoading = true;
  final _formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final entries = await FeatureService.getLoginHistory(user.id);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Login',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text('Belum ada riwayat login.',
                      style: GoogleFonts.hankenGrotesk(
                          color: AppColors.secondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryFixed,
                        child: Icon(Icons.devices, color: AppColors.primary),
                      ),
                      title: Text(entry.device,
                          style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${_formatter.format(entry.timestamp)} • IP ${entry.ipAddress}'),
                    );
                  },
                ),
    );
  }
}
