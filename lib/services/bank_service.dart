import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
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

  static Exception _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('PGRST205') ||
        message.contains('Could not find the table')) {
      return Exception(
        'Tabel Supabase belum dibuat. Jalankan supabase/schema.sql di Supabase SQL Editor.',
      );
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
    return user;
  }

  static AppUser _userFromRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      username: row['username'] as String,
      email: row['email'] as String,
      fullName: row['fullname'] as String,
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
    final rows = await _client
        .from('transaction')
        .select('*, sender:account!transaction_senderaccountid_fkey(*), receiver:account!transaction_receiveraccountid_fkey(*)')
        .or('senderaccountid.eq.$accountId,receiveraccountid.eq.$accountId')
        .order('createdat', ascending: false);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      final sender = Map<String, dynamic>.from(map['sender'] as Map);
      final receiver = Map<String, dynamic>.from(map['receiver'] as Map);
      final isCredit = map['receiveraccountid'] == accountId;
      final createdAt = DateTime.parse(map['createdat'] as String).toLocal();
      final counterparty = isCredit ? sender : receiver;
      final status = (map['status'] as String).toUpperCase() == 'SUCCESS'
          ? 'Berhasil'
          : map['status'] as String;

      return Transaction(
        id: map['referencenumber'] as String,
        title: isCredit ? 'Transfer Masuk' : 'Transfer Keluar',
        subtitle:
            '${_dateFormatter.format(createdAt)} • ${_timeFormatter.format(createdAt)}',
        amount: (map['amount'] as num).toDouble(),
        isCredit: isCredit,
        date: _dateFormatter.format(createdAt),
        category: isCredit ? 'Pemasukan' : 'Transfer',
        status: status,
        recipientName: counterparty['bankname'] as String?,
        recipientAccount:
            '${counterparty['bankname']} - ${counterparty['accountnumber']}',
        recipientBank: counterparty['bankname'] as String?,
      );
    }).toList();
  }

  static Future<Transaction> createTransfer(TransferDraft draft) async {
    final sender = SessionManager.currentAccount;
    if (sender == null) {
      throw Exception('Rekening sumber tidak ditemukan. Silakan login ulang.');
    }

    final receiverRows = await _client
        .from('account')
        .select()
        .eq('accountnumber', draft.receiverAccountNumber)
        .eq('bankname', draft.receiverBankName)
        .limit(1);

    if (receiverRows.isEmpty) {
      throw Exception('Rekening tujuan tidak ditemukan di database.');
    }

    final receiver =
        _accountFromRow(Map<String, dynamic>.from(receiverRows.first as Map));
    final total = draft.amount + draft.fee;
    if (sender.balance < total) {
      throw Exception('Saldo tidak mencukupi.');
    }

    await _client
        .from('account')
        .update({'balance': sender.balance - total}).eq('id', sender.id);
    await _client
        .from('account')
        .update({'balance': receiver.balance + draft.amount}).eq('id', receiver.id);

    final referenceNumber = 'TRF-${DateTime.now().millisecondsSinceEpoch}';
    final row = await _client
        .from('transaction')
        .insert({
          'id': _id('TRX'),
          'senderaccountid': sender.id,
          'receiveraccountid': receiver.id,
          'amount': draft.amount,
          'fee': draft.fee,
          'note': draft.note,
          'status': 'SUCCESS',
          'referencenumber': referenceNumber,
        })
        .select()
        .single();

    final updatedSender = await getPrimaryAccount(sender.userId);
    if (updatedSender != null && SessionManager.currentUser != null) {
      SessionManager.setSession(SessionManager.currentUser!, updatedSender);
    }

    final createdAt = DateTime.parse(row['createdat'] as String).toLocal();
    return Transaction(
      id: referenceNumber,
      title: 'Transfer Keluar',
      subtitle:
          '${_dateFormatter.format(createdAt)} • ${_timeFormatter.format(createdAt)}',
      amount: draft.amount,
      isCredit: false,
      date: _dateFormatter.format(createdAt),
      category: 'Transfer',
      status: 'Berhasil',
      recipientAccount: '${receiver.bankName} - ${receiver.accountNumber}',
      recipientBank: receiver.bankName,
    );
  }
}
