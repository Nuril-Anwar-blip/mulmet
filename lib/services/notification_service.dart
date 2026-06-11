import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bank_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      category: map['category'] as String? ?? 'Umum',
      createdAt: DateTime.parse(map['createdat'] as String).toLocal(),
      isRead: (map['isread'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'createdat': createdAt.toIso8601String(),
      'isread': isRead,
    };
  }
}

class NotificationService {
  NotificationService._();

  static const _localKeyPrefix = 'notifications';
  static final _client = Supabase.instance.client;

  static String _storageKey(String userId) => '$_localKeyPrefix:$userId';

  static Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final rows = await _client
          .from('notification')
          .select()
          .eq('userid', userId)
          .order('createdat', ascending: false);
      if (rows.isNotEmpty) {
        return rows
            .map((row) =>
                AppNotification.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
      }
    } catch (_) {}

    return _getLocalNotifications(userId);
  }

  static Future<int> getUnreadCount(String userId) async {
    final notifications = await getNotifications(userId);
    return notifications.where((item) => !item.isRead).length;
  }

  static Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _client
          .from('notification')
          .update({'isread': true})
          .eq('id', notificationId)
          .eq('userid', userId);
      return;
    } catch (_) {}

    final notifications = await _getLocalNotifications(userId);
    final updated = notifications
        .map((item) => item.id == notificationId
            ? AppNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                category: item.category,
                createdAt: item.createdAt,
                isRead: true,
              )
            : item)
        .toList();
    await _saveLocalNotifications(userId, updated);
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notification')
          .update({'isread': true})
          .eq('userid', userId);
      return;
    } catch (_) {}

    final notifications = await _getLocalNotifications(userId);
    final updated = notifications
        .map((item) => AppNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              category: item.category,
              createdAt: item.createdAt,
              isRead: true,
            ))
        .toList();
    await _saveLocalNotifications(userId, updated);
  }

  static Future<void> push({
    required String userId,
    required String title,
    required String body,
    String category = 'Umum',
  }) async {
    final notification = AppNotification(
      id: 'NOTIF-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      createdAt: DateTime.now(),
    );

    try {
      await _client.from('notification').insert({
        'id': notification.id,
        'userid': userId,
        'title': title,
        'body': body,
        'category': category,
        'isread': false,
        'createdat': notification.createdAt.toIso8601String(),
      });
      return;
    } catch (_) {}

    final notifications = await _getLocalNotifications(userId);
    await _saveLocalNotifications(userId, [notification, ...notifications]);
  }

  static Future<void> syncFromActivity(String userId) async {
    final account = await BankService.getPrimaryAccount(userId);
    if (account == null) return;

    final transactions = await BankService.getTransactions(account.id);
    final existing = await getNotifications(userId);
    final existingBodies = existing.map((item) => item.body).toSet();

    for (final tx in transactions.take(5)) {
      final body =
          '${tx.title} sebesar Rp ${tx.amount.toStringAsFixed(0)} • ${tx.status}';
      if (existingBodies.contains(body)) continue;
      await push(
        userId: userId,
        title: 'Aktivitas Rekening',
        body: body,
        category: tx.category,
      );
    }
  }

  static Future<List<AppNotification>> _getLocalNotifications(
      String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_storageKey(userId));
    if (encoded == null || encoded.isEmpty) return [];

    final decoded = jsonDecode(encoded);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((row) => AppNotification.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<void> _saveLocalNotifications(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = notifications.map((item) => item.toMap()).toList();
    await prefs.setString(_storageKey(userId), jsonEncode(rows));
  }
}
