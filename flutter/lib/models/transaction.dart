enum TransactionType {
  customer_debit,
  customer_credit,
  driver_debit,
  driver_credit,
  store_debit,
  store_credit
}

class Transaction {
  final int id;
  final TransactionType type;
  final int? referenceId;
  final String? referenceType;
  final int? customerId;
  final int? driverId;
  final int? storeId;
  final double amount;
  final String? notes;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    this.referenceId,
    this.referenceType,
    this.customerId,
    this.driverId,
    this.storeId,
    required this.amount,
    this.notes,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: _parseType(json['type']),
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      customerId: json['customer_id'],
      driverId: json['driver_id'],
      storeId: json['store_id'],
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static TransactionType _parseType(String type) {
    return TransactionType.values.firstWhere(
          (e) => e.name == type,
      orElse: () => TransactionType.customer_debit,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'reference_id': referenceId,
    'reference_type': referenceType,
    'customer_id': customerId,
    'driver_id': driverId,
    'store_id': storeId,
    'amount': amount,
    'notes': notes,
  };
}