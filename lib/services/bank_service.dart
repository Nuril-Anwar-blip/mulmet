import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class SessionManager {
  static AppUser? currentUser;
  static BankAccount? currentAccount;

  static void setSession(AppUser user, BankAccount? account) {
    currentUser = user;
    currentAccount = account;
  }

  static void clear() {
    currentUser = null;
    currentAccount = null;
  }
}

class BankService {
  BankService._();

  static const _sessionUserIdKey = 'current_user_id';
  static final _client = Supabase.instance.client;
  static final _dateFormatter = DateFormat('dd MMM', 'id_ID');
  static final _timeFormatter = DateFormat('HH:mm', 'id_ID');

  static String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';
  }

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static String _usernameFromEmail(String email) {
    final base = email.trim().split('@').first.replaceAll(RegExp(r'\W+'), '');
    return base.isEmpty ? _id('user') : base.toLowerCase();
  }

  static String _generateAccountNumber() {
    final random = Random();
    return List.generate(10, (_) => random.nextInt(10)).join();
  }

  static String _cleanAccountNumber(String accountNumber) {
    return accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static Exception _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('PGRST205') ||
        message.contains('Could not find the table')) {
      return Exception(
        'Tabel Supabase belum dibuat. Jalankan supabase/schema.sql di Supabase SQL Editor.',
      );
    }
    if (message.contains('PGRST202') ||
        message.contains('create_transfer_atomic') ||
        message.contains('Could not find the function')) {
      return Exception(
        'Function transfer belum dibuat. Jalankan supabase/mobile_banking_latest_database.sql di Supabase SQL Editor.',
      );
    }
    if (message.contains('column') && message.contains('does not exist')) {
      return Exception(
        'Struktur database belum terbaru. Jalankan supabase/mobile_banking_latest_database.sql di Supabase SQL Editor.',
      );
    }
    if (message.contains('23505') ||
        message.contains('duplicate key') ||
        message.contains('already exists')) {
      if (message.contains('email')) {
        return Exception('Email sudah terdaftar. Gunakan email lain atau login.');
      }
      if (message.contains('username')) {
        return Exception('Username sudah terdaftar. Gunakan email lain.');
      }
      return Exception('Data sudah ada di database.');
    }
    if (message.contains('row-level security') ||
        message.contains('Unauthorized') ||
        message.contains('42501')) {
      return Exception(
        'Akses Supabase ditolak oleh RLS. Jalankan supabase/fix_demo_access.sql di Supabase SQL Editor.',
      );
    }
    return Exception(message.replaceFirst('Exception: ', ''));
  }

  static Future<void> _persistSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, userId);
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionUserIdKey);
    if (userId == null || userId.isEmpty) return false;

    try {
      final userRow =
          await _client.from('user').select().eq('id', userId).limit(1).maybeSingle();
      if (userRow == null) {
        await prefs.remove(_sessionUserIdKey);
        return false;
      }

      final user = _userFromRow(Map<String, dynamic>.from(userRow));
      final account = await getPrimaryAccount(user.id);
      SessionManager.setSession(user, account);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    SessionManager.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
  }

  static Future<AppUser> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final credential = usernameOrEmail.trim();
    late final List<dynamic> rows;
    try {
      rows = await _client
          .from('user')
          .select()
          .or('username.eq.$credential,email.eq.$credential')
          .limit(1);
    } catch (error) {
      throw _friendlyError(error);
    }

    if (rows.isEmpty) {
      throw Exception('Username atau email tidak ditemukan.');
    }

    final row = Map<String, dynamic>.from(rows.first as Map);
    final savedPassword = row['password'] as String;
    final hashedPassword = _hashPassword(password);
    if (savedPassword != password && savedPassword != hashedPassword) {
      throw Exception('Password salah.');
    }

    final user = _userFromRow(row);
    final account = await getPrimaryAccount(user.id);
    SessionManager.setSession(user, account);
    await _persistSession(user.id);
    await _logLogin(user.id);
    return user;
  }

  static Future<AppUser> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
  }) async {
    final now = DateTime.now().toIso8601String();
    final userId = _id('USR');

    late final Map<String, dynamic> userRow;
    late final Map<String, dynamic> accountRow;
    try {
      userRow = await _client
          .from('user')
          .insert({
            'id': userId,
            'username': _usernameFromEmail(email),
            'password': _hashPassword(password),
            'email': email.trim(),
            'fullname': fullName.trim(),
            'phone': phone?.trim(),
            'transactionpin': '123456',
            'updatedat': now,
          })
          .select()
          .single();

      accountRow = await _client
          .from('account')
          .insert({
            'id': _id('ACC'),
            'userid': userId,
            'accountnumber': _generateAccountNumber(),
            'balance': 12450000.0,
            'bankname': 'Mandiri',
          })
          .select()
          .single();
    } catch (error) {
      throw _friendlyError(error);
    }

    final user = _userFromRow(Map<String, dynamic>.from(userRow));
    final account = _accountFromRow(Map<String, dynamic>.from(accountRow));
    SessionManager.setSession(user, account);
    await _persistSession(user.id);
    return user;
  }

  static AppUser _userFromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      username: row['username'] as String,
      email: row['email'] as String,
      fullName: row['fullname'] as String,
      phone: row['phone'] as String?,
    );
  }

  static BankAccount _accountFromRow(Map<String, dynamic> row) {
    return BankAccount(
      id: row['id'] as String,
      userId: row['userid'] as String,
      accountNumber: row['accountnumber'] as String,
      balance: (row['balance'] as num).toDouble(),
      bankName: row['bankname'] as String,
    );
  }

  static Future<void> _logLogin(String userId) async {
    try {
      await _client.from('loginlog').insert({
        'id': _id('LOG'),
        'userid': userId,
        'device': 'Flutter App',
        'ipaddress': '0.0.0.0',
      });
    } catch (_) {
      // Login should not fail just because logging is unavailable.
    }
  }

  static Future<BankAccount?> getPrimaryAccount(String userId) async {
    final rows = await _client
        .from('account')
        .select()
        .eq('userid', userId)
        .limit(1);

    if (rows.isEmpty) return null;
    return _accountFromRow(Map<String, dynamic>.from(rows.first as Map));
  }

  static Future<List<FavoriteRecipient>> getFavorites(String userId) async {
    final rows = await _client
        .from('favorite')
        .select()
        .eq('userid', userId)
        .order('name');

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      return FavoriteRecipient(
        id: map['id'] as String,
        name: map['name'] as String,
        accountNumber: map['accountnumber'] as String,
        bankName: map['bankname'] as String,
      );
    }).toList();
  }

  static Future<List<Transaction>> getTransactions(String accountId) async {
    late List<dynamic> rows;
    try {
      rows = accountId.isEmpty
          ? <dynamic>[]
          : await _client
              .from('transaction')
              .select()
              .or('senderaccountid.eq.$accountId,receiveraccountid.eq.$accountId')
              .order('createdat', ascending: false);
    } catch (error) {
      if (!error.toString().contains('createdat')) {
        throw _friendlyError(error);
      }
      rows = accountId.isEmpty
          ? <dynamic>[]
          : await _client
              .from('transaction')
              .select()
              .or('senderaccountid.eq.$accountId,receiveraccountid.eq.$accountId');
    }

    if (rows.isEmpty) {
      try {
        rows = await _client
            .from('transaction')
            .select()
            .order('createdat', ascending: false);
      } catch (error) {
        if (!error.toString().contains('createdat')) {
          throw _friendlyError(error);
        }
        rows = await _client.from('transaction').select();
      }
    }

    final accountIds = <String>{};
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final senderId = map['senderaccountid'] as String?;
      final receiverId = map['receiveraccountid'] as String?;
      if (senderId != null) accountIds.add(senderId);
      if (receiverId != null) accountIds.add(receiverId);
    }

    final accountRows = accountIds.isEmpty
        ? <dynamic>[]
        : await _client
            .from('account')
            .select()
            .inFilter('id', accountIds.toList());
    final accountsById = {
      for (final row in accountRows)
        (row as Map)['id'] as String: Map<String, dynamic>.from(row),
    };

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final isCredit = map['receiveraccountid'] == accountId;
      final createdAt = _transactionCreatedAt(map);
      final sender = accountsById[map['senderaccountid']];
      final receiver = accountsById[map['receiveraccountid']];
      final counterparty = isCredit ? sender : receiver;
      final counterpartyBank = counterparty?['bankname'] as String?;
      final counterpartyNumber = counterparty?['accountnumber'] as String?;

      return Transaction(
        id: _stringOrFallback(map['referencenumber'], map['id'] as String),
        title: isCredit ? 'Transfer Masuk' : 'Transfer Keluar',
        subtitle:
            '${_dateFormatter.format(createdAt)} • ${_timeFormatter.format(createdAt)}',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        isCredit: isCredit,
        date: _dateFormatter.format(createdAt),
        category: isCredit ? 'Pemasukan' : 'Transfer',
        status: _transactionStatus(map['status']),
        recipientName: counterpartyBank,
        recipientAccount: counterpartyBank == null || counterpartyNumber == null
            ? map[isCredit ? 'senderaccountid' : 'receiveraccountid'] as String?
            : '$counterpartyBank - $counterpartyNumber',
        recipientBank: counterpartyBank,
      );
    }).toList();
  }

  static Future<AppUser> updateProfile({
    required String email,
    String? phone,
  }) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    }

    try {
      final row = await _client
          .from('user')
          .update({
            'email': email.trim(),
            'phone': phone?.trim(),
            'updatedat': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .single();
      final updatedUser = _userFromRow(Map<String, dynamic>.from(row));
      SessionManager.setSession(updatedUser, SessionManager.currentAccount);
      await _persistSession(updatedUser.id);
      return updatedUser;
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  static Future<bool> verifyTransactionPin(String pin) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    }
    if (pin.length != 6) return false;

    try {
      final row = await _client
          .from('user')
          .select('transactionpin')
          .eq('id', user.id)
          .single();
      final savedPin = (row['transactionpin'] as String?) ?? '123456';
      return pin == savedPin;
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  static Future<void> changeTransactionPin({
    required String oldPin,
    required String newPin,
  }) async {
    if (!await verifyTransactionPin(oldPin)) {
      throw Exception('PIN lama salah.');
    }
    final user = SessionManager.currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    }

    try {
      await _client
          .from('user')
          .update({'transactionpin': newPin, 'updatedat': DateTime.now().toIso8601String()})
          .eq('id', user.id);
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  static Future<VerifiedAccount> verifyRecipientAccount({
    required String accountNumber,
    required String bankName,
  }) async {
    try {
      final accountRow = await _client
          .from('account')
          .select()
          .eq('accountnumber', _cleanAccountNumber(accountNumber))
          .eq('bankname', bankName.trim())
          .limit(1)
          .maybeSingle();

      if (accountRow == null) {
        throw Exception('Rekening tujuan tidak ditemukan di database.');
      }

      final account = Map<String, dynamic>.from(accountRow);
      final userRow = await _client
          .from('user')
          .select('fullname')
          .eq('id', account['userid'] as String)
          .limit(1)
          .maybeSingle();
      final ownerName = userRow == null
          ? 'Nasabah Mandiri'
          : (Map<String, dynamic>.from(userRow)['fullname'] as String);

      return VerifiedAccount(
        accountId: account['id'] as String,
        userId: account['userid'] as String,
        accountNumber: account['accountnumber'] as String,
        bankName: account['bankname'] as String,
        ownerName: ownerName,
      );
    } catch (error) {
      if (error.toString().contains('Rekening tujuan tidak ditemukan')) {
        rethrow;
      }
      throw _friendlyError(error);
    }
  }

  static Future<void> addFavoriteRecipient(VerifiedAccount recipient) async {
    final user = SessionManager.currentUser;
    if (user == null) {
      throw Exception('Sesi tidak ditemukan. Silakan login ulang.');
    }

    try {
      await _client.from('favorite').upsert({
        'id': 'FAV-${user.id}-${recipient.accountNumber}',
        'userid': user.id,
        'name': recipient.ownerName,
        'accountnumber': recipient.accountNumber,
        'bankname': recipient.bankName,
      });
    } catch (error) {
      throw _friendlyError(error);
    }
  }

  static Future<Transaction> createTransfer(TransferDraft draft) async {
    final sender = SessionManager.currentAccount;
    if (sender == null) {
      throw Exception('Rekening sumber tidak ditemukan. Silakan login ulang.');
    }

    late final VerifiedAccount receiver;
    try {
      receiver = await verifyRecipientAccount(
        accountNumber: draft.receiverAccountNumber,
        bankName: draft.receiverBankName,
      );
    } catch (error) {
      rethrow;
    }

    late final Map<String, dynamic> row;
    try {
      final response = await _client.rpc('create_transfer_atomic', params: {
        'p_sender_account_id': sender.id,
        'p_receiver_account_number': _cleanAccountNumber(draft.receiverAccountNumber),
        'p_receiver_bank_name': draft.receiverBankName,
        'p_amount': draft.amount,
        'p_fee': draft.fee,
        'p_note': draft.note,
      });

      if (response is List && response.isNotEmpty) {
        row = Map<String, dynamic>.from(response.first as Map);
      } else if (response is Map) {
        row = Map<String, dynamic>.from(response);
      } else {
        throw Exception('Transaksi gagal dibuat.');
      }
    } catch (error) {
      throw _friendlyError(error);
    }

    final updatedSender = await getPrimaryAccount(sender.userId);
    if (updatedSender != null && SessionManager.currentUser != null) {
      SessionManager.setSession(SessionManager.currentUser!, updatedSender);
    }

    final createdAt = _transactionCreatedAt(Map<String, dynamic>.from(row));
    return Transaction(
      id: row['referencenumber'] as String,
      title: 'Transfer Keluar',
      subtitle:
          '${_dateFormatter.format(createdAt)} • ${_timeFormatter.format(createdAt)}',
      amount: draft.amount,
      isCredit: false,
      date: _dateFormatter.format(createdAt),
      category: 'Transfer',
      status: 'Berhasil',
      recipientName: draft.receiverName ?? receiver.ownerName,
      recipientAccount: '${receiver.bankName} - ${receiver.accountNumber}',
      recipientBank: receiver.bankName,
    );
  }
}
