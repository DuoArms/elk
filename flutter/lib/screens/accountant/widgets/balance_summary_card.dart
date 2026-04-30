import 'package:flutter/material.dart';
import '../../../models/balance_summary.dart';

class BalanceSummaryCard extends StatelessWidget {
  final BalanceSummary summary;
  const BalanceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('الملخص المالي',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _summaryTile('إجمالي الإيرادات', summary.totalRevenue, Colors.green),
                _summaryTile('مدفوعات السائقين', summary.totalDriverPayouts, Colors.orange),
                _summaryTile('مشتريات المتاجر', summary.totalStorePurchases, Colors.blue),
                _summaryTile('ديون الزبائن', summary.customersDebt, Colors.red),
                _summaryTile('صافي الربح', summary.netProfit, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, double value, Color color) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        '${value.toStringAsFixed(2)} ل.س',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}