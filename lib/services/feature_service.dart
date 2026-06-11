import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feature_models.dart';
import '../models/models.dart';
import 'bank_service.dart';
import 'notification_service.dart';

class FeatureService {
  FeatureService._();

  static final _client = Supabase.instance.client;

  static String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

  static String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static bool _isMissingTable(Object error) {
    final message = error.toString();
    return message.contains('PGRST205') ||
        message.contains('Could not find the table');
  }

  // ─── Favorites ───────────────────────────────────────────────

  static Future<void> deleteFavorite(String favoriteId) async {
    try {
      await _client.from('favorite').delete().eq('id', favoriteId);
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      await _deleteLocalFavorite(favoriteId);
    }
  }

  static Future<void> updateFavorite({
    required String favoriteId,
    required String name,
    required String accountNumber,
    required String bankName,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) throw Exception('Sesi tidak ditemukan.');

    try {
      await _client.from('favorite').update({
        'name': name.trim(),
        'accountnumber': accountNumber.trim(),
        'bankname': bankName.trim(),
      }).eq('id', favoriteId).eq('userid', user.id);
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      await _updateLocalFavorite(
        favoriteId: favoriteId,
        name: name,
        accountNumber: accountNumber,
        bankName: bankName,
      );
    }
  }

  static Future<void> _deleteLocalFavorite(String favoriteId) async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    final favorites = await BankService.getFavorites(user.id);
    final updated = favorites.where((f) => f.id != favoriteId).toList();
    await _saveLocalFavorites(user.id, updated);
  }

  static Future<void> _updateLocalFavorite({
    required String favoriteId,
    required String name,
    required String accountNumber,
    required String bankName,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) return;
    final favorites = await BankService.getFavorites(user.id);
    final updated = favorites.map((f) {
      if (f.id != favoriteId) return f;
      return FavoriteRecipient(
        id: f.id,
        name: name.trim(),
        accountNumber: accountNumber.trim(),
        bankName: bankName.trim(),
      );
    }).toList();
    await _saveLocalFavorites(user.id, updated);
  }

  static Future<void> _saveLocalFavorites(
    String userId,
    List<FavoriteRecipient> favorites,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = favorites
        .map((f) => {
              'id': f.id,
              'name': f.name,
              'accountnumber': f.accountNumber,
              'bankname': f.bankName,
            })
        .toList();
    await prefs.setString('local_favorites:$userId', jsonEncode(rows));
  }

  // ─── Utility (PLN / Pulsa) ─────────────────────────────────

  static Future<UtilityPayment> payUtility({
    required String type,
    required String customerId,
    required String customerName,
    required double amount,
  }) async {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    if (user == null || account == null) {
      throw Exception('Sesi tidak ditemukan.');
    }
    if (amount <= 0) throw Exception('Nominal harus lebih dari 0.');
    if (account.balance < amount) throw Exception('Saldo tidak cukup.');

    final payment = UtilityPayment(
      id: _id('UTL'),
      userId: user.id,
      type: type,
      customerId: customerId.trim(),
      customerName: customerName.trim(),
      amount: amount,
      createdAt: DateTime.now(),
    );

    try {
      await _client.from('utility_payment').insert(payment.toMap());
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      await _saveLocalUtility(payment);
    }

    final newBalance = account.balance - amount;
    await _client
        .from('account')
        .update({'balance': newBalance})
        .eq('id', account.id);
    SessionManager.setSession(user, account.copyWith(balance: newBalance));

    await _client.from('transaction').insert({
      'id': _id('TX'),
      'senderaccountid': account.id,
      'receiveraccountid': account.id,
      'amount': amount,
      'fee': 0,
      'note': '$type - $customerName ($customerId)',
      'status': 'SUCCESS',
      'referencenumber': payment.id,
      'createdat': payment.createdAt.toIso8601String(),
    });

    await NotificationService.push(
      userId: user.id,
      title: 'Pembayaran $type Berhasil',
      body: 'Pembayaran $customerName sebesar Rp ${amount.toStringAsFixed(0)} berhasil.',
      category: 'Tagihan',
    );

    return payment;
  }

  static Future<void> _saveLocalUtility(UtilityPayment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_utilities:${payment.userId}';
    final existing = prefs.getString(key);
    final list = existing == null
        ? <dynamic>[]
        : (jsonDecode(existing) as List).toList();
    list.insert(0, payment.toMap());
    await prefs.setString(key, jsonEncode(list));
  }

  // ─── Deposito ──────────────────────────────────────────────

  static Future<DepositAccount> createDeposit({
    required double amount,
    required int termMonths,
    required double interestRate,
  }) async {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    if (user == null || account == null) throw Exception('Sesi tidak ditemukan.');
    if (amount < 1000000) throw Exception('Minimum deposito Rp 1.000.000.');
    if (account.balance < amount) throw Exception('Saldo tidak cukup.');

    final now = DateTime.now();
    final deposit = DepositAccount(
      id: _id('DEP'),
      userId: user.id,
      amount: amount,
      interestRate: interestRate,
      termMonths: termMonths,
      startDate: now,
      maturityDate: DateTime(now.year, now.month + termMonths, now.day),
    );

    try {
      await _client.from('deposit').insert(deposit.toMap());
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      await _saveLocalDeposit(deposit);
    }

    await _client
        .from('account')
        .update({'balance': account.balance - amount})
        .eq('id', account.id);
    SessionManager.setSession(
      user,
      account.copyWith(balance: account.balance - amount),
    );

    await NotificationService.push(
      userId: user.id,
      title: 'Deposito Dibuka',
      body: 'Deposito Rp ${amount.toStringAsFixed(0)} berhasil dibuka.',
      category: 'Deposito',
    );

    return deposit;
  }

  static Future<List<DepositAccount>> getDeposits(String userId) async {
    try {
      final rows =
          await _client.from('deposit').select().eq('userid', userId);
      return rows
          .map((r) => DepositAccount.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (error) {
      if (_isMissingTable(error)) return await _getLocalDeposits(userId);
      rethrow;
    }
  }

  static Future<void> _saveLocalDeposit(DepositAccount deposit) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_deposits:${deposit.userId}';
    final list = await _readLocalList(key);
    list.insert(0, deposit.toMap());
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<List<DepositAccount>> _getLocalDeposits(String userId) async {
    final list = await _readLocalList('local_deposits:$userId');
    return list
        .map((m) => DepositAccount.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  // ─── Credit Card ───────────────────────────────────────────

  static Future<List<CreditCardAccount>> getCreditCards(String userId) async {
    try {
      final rows =
          await _client.from('credit_card').select().eq('userid', userId);
      if (rows.isNotEmpty) {
        return rows
            .map((r) =>
                CreditCardAccount.fromMap(Map<String, dynamic>.from(r)))
            .toList();
      }
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
    }
    return _defaultCreditCard(userId);
  }

  static List<CreditCardAccount> _defaultCreditCard(String userId) {
    return [
      CreditCardAccount(
        id: 'CC-DEFAULT',
        userId: userId,
        cardNumber: '4532 **** **** 8821',
        limit: 15000000,
        used: 4250000,
        minimumPayment: 425000,
        dueDate: DateTime.now().add(const Duration(days: 14)),
      ),
    ];
  }

  static Future<void> payCreditCard({
    required String cardId,
    required double amount,
  }) async {
    final user = SessionManager.currentUser;
    final account = SessionManager.currentAccount;
    if (user == null || account == null) throw Exception('Sesi tidak ditemukan.');
    if (account.balance < amount) throw Exception('Saldo tidak cukup.');

    try {
      final rows = await _client
          .from('credit_card')
          .select()
          .eq('id', cardId)
          .limit(1);
      if (rows.isNotEmpty) {
        final card = CreditCardAccount.fromMap(
            Map<String, dynamic>.from(rows.first));
        await _client.from('credit_card').update({
          'usedamount': (card.used - amount).clamp(0, card.limit),
        }).eq('id', cardId);
      }
    } catch (_) {}

    await _client
        .from('account')
        .update({'balance': account.balance - amount})
        .eq('id', account.id);
    SessionManager.setSession(
      user,
      account.copyWith(balance: account.balance - amount),
    );

    await NotificationService.push(
      userId: user.id,
      title: 'Pembayaran Kartu Kredit',
      body: 'Pembayaran Rp ${amount.toStringAsFixed(0)} berhasil.',
      category: 'Kartu Kredit',
    );
  }

  // ─── Scheduled Transfer ─────────────────────────────────────

  static Future<ScheduledTransfer> createScheduledTransfer({
    required String receiverAccountNumber,
    required String receiverBankName,
    required String receiverName,
    required double amount,
    required String frequency,
    required DateTime nextRunDate,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) throw Exception('Sesi tidak ditemukan.');

    final scheduled = ScheduledTransfer(
      id: _id('SCH'),
      userId: user.id,
      receiverAccountNumber: receiverAccountNumber,
      receiverBankName: receiverBankName,
      receiverName: receiverName,
      amount: amount,
      frequency: frequency,
      nextRunDate: nextRunDate,
    );

    try {
      await _client.from('scheduled_transfer').insert(scheduled.toMap());
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      await _saveLocalScheduled(scheduled);
    }

    await NotificationService.push(
      userId: user.id,
      title: 'Transfer Terjadwal Dibuat',
      body: 'Transfer ke $receiverName dijadwalkan.',
      category: 'Transfer',
    );

    return scheduled;
  }

  static Future<List<ScheduledTransfer>> getScheduledTransfers(
      String userId) async {
    try {
      final rows = await _client
          .from('scheduled_transfer')
          .select()
          .eq('userid', userId)
          .order('nextrundate');
      return rows
          .map((r) =>
              ScheduledTransfer.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (error) {
      if (_isMissingTable(error)) return _getLocalScheduled(userId);
      rethrow;
    }
  }

  static Future<void> deleteScheduledTransfer(String id) async {
    try {
      await _client.from('scheduled_transfer').delete().eq('id', id);
    } catch (error) {
      if (!_isMissingTable(error)) rethrow;
      final user = SessionManager.currentUser;
      if (user == null) return;
      final scheduled = await _getLocalScheduled(user.id);
      final list = scheduled
          .where((s) => s.id != id)
          .map((s) => s.toMap())
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'local_scheduled:${user.id}', jsonEncode(list));
    }
  }

  static Future<void> _saveLocalScheduled(ScheduledTransfer s) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_scheduled:${s.userId}';
    final list = await _readLocalList(key);
    list.insert(0, s.toMap());
    await prefs.setString(key, jsonEncode(list));
  }

  static Future<List<ScheduledTransfer>> _getLocalScheduled(
      String userId) async {
    final list = await _readLocalList('local_scheduled:$userId');
    return list
        .map((m) =>
            ScheduledTransfer.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  // ─── Login History ─────────────────────────────────────────

  static Future<List<LoginHistoryEntry>> getLoginHistory(
      String userId) async {
    try {
      final rows = await _client
          .from('loginlog')
          .select()
          .eq('userid', userId)
          .order('timestamp', ascending: false)
          .limit(50);
      return rows
          .map((r) =>
              LoginHistoryEntry.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Password Reset ────────────────────────────────────────

  static Future<PasswordResetRequest> requestPasswordResetToken({
    required String email,
  }) async {
    final rows = await _client
        .from('user')
        .select('id, email')
        .eq('email', email.trim().toLowerCase())
        .limit(1);
    if (rows.isEmpty) throw Exception('Email tidak terdaftar.');

    final userId = (rows.first as Map)['id'] as String;
    final token = List.generate(6, (_) => Random().nextInt(10)).join();
    final expires = DateTime.now().add(const Duration(minutes: 15));

    try {
      await _client.from('password_reset').upsert({
        'userid': userId,
        'token': token,
        'expiresat': expires.toIso8601String(),
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reset_token:$email', token);
      await prefs.setInt(
          'reset_expiry:$email', expires.millisecondsSinceEpoch);
    }

    await NotificationService.push(
      userId: userId,
      title: 'Kode Reset Password',
      body: 'Kode reset Anda: $token (berlaku 15 menit).',
      category: 'Keamanan',
    );

    return PasswordResetRequest(email: email.trim().toLowerCase(), token: token);
  }

  static Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw Exception('Password minimal 8 karakter.');
    }

    final rows = await _client
        .from('user')
        .select('id')
        .eq('email', email.trim().toLowerCase())
        .limit(1);
    if (rows.isEmpty) throw Exception('Email tidak ditemukan.');
    final userId = (rows.first as Map)['id'] as String;

    var tokenValid = false;
    try {
      final resetRows = await _client
          .from('password_reset')
          .select()
          .eq('userid', userId)
          .eq('token', token.trim())
          .limit(1);
      if (resetRows.isNotEmpty) {
        final expires = DateTime.parse(
            resetRows.first['expiresat'] as String);
        tokenValid = DateTime.now().isBefore(expires);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('reset_token:$email');
      final expiry = prefs.getInt('reset_expiry:$email');
      tokenValid = saved == token.trim() &&
          expiry != null &&
          DateTime.now().millisecondsSinceEpoch < expiry;
    }

    if (!tokenValid) throw Exception('Kode reset tidak valid atau kedaluwarsa.');

    await _client.from('user').update({
      'password': _hashPassword(newPassword),
      'updatedat': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    try {
      await _client.from('password_reset').delete().eq('userid', userId);
    } catch (_) {}
  }

  // ─── Financial Summary ─────────────────────────────────────

  static FinancialSummary buildSummary(List<Transaction> transactions) {
    var income = 0.0;
    var expense = 0.0;
    final byCategory = <String, double>{};

    for (final tx in transactions) {
      if (tx.isCredit) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        byCategory[tx.category] =
            (byCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      expenseByCategory: byCategory,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  static Future<List<dynamic>> _readLocalList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded;
  }
}

extension _BankAccountCopy on BankAccount {
  BankAccount copyWith({
    double? balance,
    String? label,
  }) {
    return BankAccount(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      balance: balance ?? this.balance,
      bankName: bankName,
      label: label ?? this.label,
    );
  }
}
