class AppUser {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      fullName: (map['fullName'] ?? map['fullname']) as String,
      phone: map['phone'] as String?,
    );
  }
}

class BankAccount {
  final String id;
  final String userId;
  final String accountNumber;
  final double balance;
  final String bankName;
  final String label;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.balance,
    required this.bankName,
    String? label,
  }) : label = label ?? 'Tabungan $bankName';

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    final bankName = (map['bankName'] ?? map['bankname']) as String;
    return BankAccount(
      id: map['id'] as String,
      userId: (map['userId'] ?? map['userid']) as String,
      accountNumber: (map['accountNumber'] ?? map['accountnumber']) as String,
      balance: (map['balance'] as num).toDouble(),
      bankName: bankName,
      label: (map['label'] as String?) ?? 'Tabungan $bankName',
    );
  }
}

class QrisDraft {
  final String merchantName;
  final String merchantCode;
  final double amount;

  QrisDraft({
    required this.merchantName,
    required this.merchantCode,
    required this.amount,
  });
}

class FavoriteRecipient {
  final String id;
  final String name;
  final String accountNumber;
  final String bankName;

  FavoriteRecipient({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
  });

  factory FavoriteRecipient.fromMap(Map<String, dynamic> map) {
    return FavoriteRecipient(
      id: map['id'] as String,
      name: map['name'] as String,
      accountNumber: map['accountNumber'] as String,
      bankName: map['bankName'] as String,
    );
  }
}

class VerifiedAccount {
  final String accountId;
  final String userId;
  final String accountNumber;
  final String bankName;
  final String ownerName;

  VerifiedAccount({
    required this.accountId,
    required this.userId,
    required this.accountNumber,
    required this.bankName,
    required this.ownerName,
  });
}

class TransferDraft {
  final String receiverAccountNumber;
  final String receiverBankName;
  final String? receiverName;
  final double amount;
  final double fee;
  final String? note;

  TransferDraft({
    required this.receiverAccountNumber,
    required this.receiverBankName,
    this.receiverName,
    required this.amount,
    this.fee = 6500,
    this.note,
  });
}

class Transaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String date;
  final String category;
  final String status;
  final String? recipientName;
  final String? recipientAccount;
  final String? recipientBank;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.category,
    this.status = 'Berhasil',
    this.recipientName,
    this.recipientAccount,
    this.recipientBank,
    this.createdAt,
  });
}

class BillInvoice {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String title;
  final double amount;
  final String status;
  final DateTime createdAt;

  BillInvoice({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.title,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory BillInvoice.fromMap(Map<String, dynamic> map) {
    return BillInvoice(
      id: map['id'] as String,
      userId: map['userid'] as String,
      customerName: map['customername'] as String,
      customerEmail: map['customeremail'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdat'] as String).toLocal(),
    );
  }
}

class Bank {
  final String name;
  final String code;

  Bank({required this.name, required this.code});
}

List<Transaction> dummyTransactions = [
  Transaction(
    id: 'MNDR-99283-X102',
    title: 'Transfer Keluar',
    subtitle: '12 Mei • 14:20',
    amount: 1250000,
    isCredit: false,
    date: '12 Mei',
    category: 'Transfer',
    status: 'Berhasil',
    recipientName: 'Ahmad Syarifuddin',
    recipientAccount: 'BCA - 882012****',
    recipientBank: 'BCA',
  ),
  Transaction(
    id: 'MNDR-99284-X103',
    title: 'Pembayaran QRIS',
    subtitle: '10 Mei • 19:45',
    amount: 45000,
    isCredit: false,
    date: '10 Mei',
    category: 'Belanja',
    status: 'Berhasil',
  ),
  Transaction(
    id: 'MNDR-99285-X104',
    title: 'Transfer Masuk',
    subtitle: '08 Mei • 09:12',
    amount: 5000000,
    isCredit: true,
    date: '08 Mei',
    category: 'Pemasukan',
    status: 'Berhasil',
  ),
  Transaction(
    id: 'MNDR-99286-X105',
    title: 'Pembayaran PLN',
    subtitle: '28 Apr • 21:00',
    amount: 342500,
    isCredit: false,
    date: '28 Apr',
    category: 'Tagihan',
    status: 'Diproses',
  ),
  Transaction(
    id: 'MNDR-99287-X106',
    title: 'Indomaret Point',
    subtitle: '24 Okt • Belanja',
    amount: 75000,
    isCredit: false,
    date: '24 Okt',
    category: 'Belanja',
    status: 'Berhasil',
  ),
  Transaction(
    id: 'MNDR-99288-X107',
    title: 'Gaji Oktober',
    subtitle: '25 Okt • Pemasukan',
    amount: 8500000,
    isCredit: true,
    date: '25 Okt',
    category: 'Pemasukan',
    status: 'Berhasil',
  ),
  Transaction(
    id: 'MNDR-99289-X108',
    title: 'Starbucks Reserve',
    subtitle: '25 Okt • Hiburan',
    amount: 58000,
    isCredit: false,
    date: '25 Okt',
    category: 'Hiburan',
    status: 'Berhasil',
  ),
];

List<Bank> popularBanks = [
  Bank(name: 'Mandiri', code: '008'),
  Bank(name: 'BCA', code: '014'),
  Bank(name: 'BRI', code: '002'),
  Bank(name: 'BNI', code: '009'),
];

List<Bank> allBanks = [
  Bank(name: 'Allo Bank Indonesia', code: '567'),
  Bank(name: 'Bank Artha Graha Internasional', code: '037'),
  Bank(name: 'Bank BCA Syariah', code: '536'),
  Bank(name: 'Bank Bengkulu', code: '133'),
  Bank(name: 'Bank BJB', code: '110'),
  Bank(name: 'Bank BTN', code: '200'),
  Bank(name: 'Citibank N.A.', code: '031'),
  Bank(name: 'Commonwealth Bank', code: '950'),
  Bank(name: 'Danamon', code: '011'),
];
