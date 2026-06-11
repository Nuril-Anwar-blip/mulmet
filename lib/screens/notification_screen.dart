import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/bank_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  final _dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = SessionManager.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    await NotificationService.syncFromActivity(user.id);
    final notifications = await NotificationService.getNotifications(user.id);
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    await NotificationService.markAllAsRead(user.id);
    await _loadNotifications();
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Transfer':
        return Icons.sync_alt;
      case 'QRIS':
        return Icons.qr_code_scanner;
      case 'Tagihan':
        return Icons.receipt_long_outlined;
      case 'Keamanan':
        return Icons.security_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: Text(
              'Tandai dibaca',
              style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          size: 64, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada notifikasi',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Material(
                        color: item.isRead
                            ? Colors.white
                            : AppColors.primaryFixed.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () async {
                            final user = SessionManager.currentUser;
                            if (user == null) return;
                            await NotificationService.markAsRead(
                                user.id, item.id);
                            await _loadNotifications();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForCategory(item.category),
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 13,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _dateFormatter.format(item.createdAt),
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 11,
                                          color: AppColors.outlineVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
