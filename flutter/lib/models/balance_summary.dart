class BalanceSummary {
  final double totalRevenue;        // إجمالي الإيرادات (أجرة التوصيل)
  final double totalDriverPayouts;  // إجمالي المدفوع للسائقين (عمولات)
  final double totalStorePurchases; // إجمالي مشترياتنا من المتاجر
  final double customersDebt;       // إجمالي ديون الزبائن علينا
  final double netProfit;           // صافي الربح (الإيرادات - مدفوعات السائقين)
  final int totalOrders;            // إجمالي الطلبات
  final int completedOrders;        // الطلبات المكتملة

  BalanceSummary({
    required this.totalRevenue,
    required this.totalDriverPayouts,
    required this.totalStorePurchases,
    required this.customersDebt,
    required this.netProfit,
    required this.totalOrders,
    required this.completedOrders,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    return BalanceSummary(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalDriverPayouts: (json['total_driver_payouts'] ?? 0).toDouble(),
      totalStorePurchases: (json['total_store_purchases'] ?? 0).toDouble(),
      customersDebt: (json['customers_debt'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
    );
  }
}