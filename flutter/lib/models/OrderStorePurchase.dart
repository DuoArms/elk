class OrderStorePurchase {
  final int orderId;
  final int storeId;
  final double totalAmount;
  final String? notes;

  OrderStorePurchase({
    required this.orderId,
    required this.storeId,
    required this.totalAmount,
    this.notes,
  });

  factory OrderStorePurchase.fromJson(Map<String, dynamic> json) => OrderStorePurchase(
    orderId: json['order_id'],
    storeId: json['store_id'],
    totalAmount: (json['total_amount'] as num).toDouble(),
    notes: json['notes'],
  );

  Map<String, dynamic> toJson() => {
    'store_id': storeId,
    'total_amount': totalAmount,
    'notes': notes,
  };
}