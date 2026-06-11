class DepositAccount {
  final String id;
  final String userId;
  final double amount;
  final double interestRate;
  final int termMonths;
  final DateTime startDate;
  final DateTime maturityDate;
  final String status;

  DepositAccount({
    required this.id,
    required this.userId,
    required this.amount,
    required this.interestRate,
    required this.termMonths,
    required this.startDate,
    required this.maturityDate,
    this.status = 'ACTIVE',
  });

  double get projectedReturn => amount * (interestRate / 100) * (termMonths / 12);

  factory DepositAccount.fromMap(Map<String, dynamic> map) {
    return DepositAccount(
      id: map['id'] as String,
      userId: map['userid'] as String,
      amount: (map['amount'] as num).toDouble(),
      interestRate: (map['interestrate'] as num).toDouble(),
      termMonths: map['termmonths'] as int,
      startDate: DateTime.parse(map['startdate'] as String).toLocal(),
      maturityDate: DateTime.parse(map['maturitydate'] as String).toLocal(),
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userid': userId,
        'amount': amount,
        'interestrate': interestRate,
        'termmonths': termMonths,
        'startdate': startDate.toIso8601String(),
        'maturitydate': maturityDate.toIso8601String(),
        'status': status,
      };
}

class CreditCardAccount {
  final String id;
  final String userId;
  final String cardNumber;
  final double limit;
  final double used;
  final double minimumPayment;
  final DateTime dueDate;

  CreditCardAccount({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.limit,
    required this.used,
    required this.minimumPayment,
    required this.dueDate,
  });

  double get available => limit - used;

  factory CreditCardAccount.fromMap(Map<String, dynamic> map) {
    return CreditCardAccount(
      id: map['id'] as String,
      userId: map['userid'] as String,
      cardNumber: map['cardnumber'] as String,
      limit: (map['creditlimit'] as num).toDouble(),
      used: (map['usedamount'] as num).toDouble(),
      minimumPayment: (map['minimumpayment'] as num).toDouble(),
      dueDate: DateTime.parse(map['duedate'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userid': userId,
        'cardnumber': cardNumber,
        'creditlimit': limit,
        'usedamount': used,
        'minimumpayment': minimumPayment,
        'duedate': dueDate.toIso8601String(),
      };
}

class ScheduledTransfer {
  final String id;
  final String userId;
  final String receiverAccountNumber;
  final String receiverBankName;
  final String receiverName;
  final double amount;
  final String frequency;
  final DateTime nextRunDate;
  final String status;

  ScheduledTransfer({
    required this.id,
    required this.userId,
    required this.receiverAccountNumber,
    required this.receiverBankName,
    required this.receiverName,
    required this.amount,
    required this.frequency,
    required this.nextRunDate,
    this.status = 'ACTIVE',
  });

  factory ScheduledTransfer.fromMap(Map<String, dynamic> map) {
    return ScheduledTransfer(
      id: map['id'] as String,
      userId: map['userid'] as String,
      receiverAccountNumber: map['receiveraccountnumber'] as String,
      receiverBankName: map['receiverbankname'] as String,
      receiverName: map['receivername'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: map['frequency'] as String,
      nextRunDate: DateTime.parse(map['nextrundate'] as String).toLocal(),
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userid': userId,
        'receiveraccountnumber': receiverAccountNumber,
        'receiverbankname': receiverBankName,
        'receivername': receiverName,
        'amount': amount,
        'frequency': frequency,
        'nextrundate': nextRunDate.toIso8601String(),
        'status': status,
      };
}

class UtilityPayment {
  final String id;
  final String userId;
  final String type;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime createdAt;

  UtilityPayment({
    required this.id,
    required this.userId,
    required this.type,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.createdAt,
  });

  factory UtilityPayment.fromMap(Map<String, dynamic> map) {
    return UtilityPayment(
      id: map['id'] as String,
      userId: map['userid'] as String,
      type: map['type'] as String,
      customerId: map['customerid'] as String,
      customerName: map['customername'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdat'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userid': userId,
        'type': type,
        'customerid': customerId,
        'customername': customerName,
        'amount': amount,
        'createdat': createdAt.toIso8601String(),
      };
}

class LoginHistoryEntry {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String device;
  final String ipAddress;

  LoginHistoryEntry({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.device,
    required this.ipAddress,
  });

  factory LoginHistoryEntry.fromMap(Map<String, dynamic> map) {
    return LoginHistoryEntry(
      id: map['id'] as String,
      userId: map['userid'] as String,
      timestamp: DateTime.parse(
        (map['timestamp'] ?? map['createdat']) as String,
      ).toLocal(),
      device: map['device'] as String,
      ipAddress: map['ipaddress'] as String,
    );
  }
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> expenseByCategory;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
  });

  double get netFlow => totalIncome - totalExpense;
}

class PasswordResetRequest {
  final String email;
  final String token;

  PasswordResetRequest({required this.email, required this.token});
}
