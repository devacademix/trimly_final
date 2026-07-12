enum TransactionType {
  deposit('DEPOSIT'),
  withdrawal('WITHDRAWAL'),
  bookingPayment('BOOKING_PAYMENT'),
  bookingRefund('BOOKING_REFUND'),
  commissionCharge('COMMISSION_CHARGE'),
  settlement('SETTLEMENT'),
  subscriptionBuy('SUBSCRIPTION_BUY');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromJson(String value) {
    return TransactionType.values.firstWhere((t) => t.value == value, orElse: () => TransactionType.deposit);
  }

  String get label {
    switch (this) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.bookingPayment:
        return 'Booking Payment';
      case TransactionType.bookingRefund:
        return 'Refund';
      case TransactionType.commissionCharge:
        return 'Platform Commission';
      case TransactionType.settlement:
        return 'Settlement';
      case TransactionType.subscriptionBuy:
        return 'Subscription Purchase';
    }
  }
}

enum TransactionStatus {
  pending('PENDING'),
  success('SUCCESS'),
  failed('FAILED');

  final String value;
  const TransactionStatus(this.value);

  static TransactionStatus fromJson(String value) {
    return TransactionStatus.values.firstWhere((s) => s.value == value, orElse: () => TransactionStatus.pending);
  }
}

class WalletTransaction {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      type: TransactionType.fromJson(json['type'] as String),
      status: TransactionStatus.fromJson(json['status'] as String),
      amount: double.parse(json['amount'].toString()),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isOutgoing => type == TransactionType.withdrawal || type == TransactionType.commissionCharge;
}

class WalletDetails {
  final double balance;
  final List<WalletTransaction> transactions;

  const WalletDetails({required this.balance, required this.transactions});

  factory WalletDetails.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] as Map<String, dynamic>;
    final txns = json['transactions'] as List? ?? [];
    return WalletDetails(
      balance: double.parse(wallet['balance'].toString()),
      transactions: txns.map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}
