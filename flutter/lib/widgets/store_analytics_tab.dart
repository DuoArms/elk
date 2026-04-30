// lib/widgets/store_analytics_tab.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StoreAnalyticsTab extends StatefulWidget {
  final ApiService api;
  const StoreAnalyticsTab({super.key, required this.api});

  @override
  State<StoreAnalyticsTab> createState() => _StoreAnalyticsTabState();
}

class _StoreAnalyticsTabState extends State<StoreAnalyticsTab> {
  List<dynamic> _stores = [];
  Map<int, double> _monthlyPurchases = {};
  bool _loading = true;
  int? _selectedMonth;
  int? _selectedYear;

  final List<int> _months = List.generate(12, (i) => i + 1);
  final List<int> _years = List.generate(5, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _loading = true);
    try {
      final stores = await widget.api.getStoresWithTotalPurchases();
      setState(() => _stores = stores);
      await _loadMonthlyPurchases();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في تحميل المتاجر: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMonthlyPurchases() async {
    if (_selectedMonth == null || _selectedYear == null) return;
    final newMonthly = <int, double>{};
    for (var store in _stores) {
      final storeId = store['id'] as int;
      try {
        final data = await widget.api.getStoreMonthlyPurchases(
          storeId,
          month: _selectedMonth,
          year: _selectedYear,
        );
        newMonthly[storeId] = _toSafeDouble(data['total_purchases']);
      } catch (e) {
        newMonthly[storeId] = 0.0;
      }
    }
    setState(() => _monthlyPurchases = newMonthly);
  }

  Future<void> _addTransaction(
      int storeId, String storeName, double currentBalance) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isPayment = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة معاملة لـ $storeName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<bool>(
              value: isPayment,
              decoration: const InputDecoration(labelText: 'نوع العملية'),
              items: const [
                DropdownMenuItem(value: true, child: Text('دفعة (سداد) ➕')),
                DropdownMenuItem(value: false, child: Text('خصم / فاتورة جديدة ➖')),
              ],
              onChanged: (v) => isPayment = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'المبلغ', prefixText: 'SYP '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')));
                return;
              }
              final transactionType = isPayment ? 'store_credit' : 'store_debit';
              try {
                await widget.api.createTransaction({
                  'type': transactionType,
                  'amount': amount,
                  'store_id': storeId,
                  'notes': notesCtrl.text,
                });
                Navigator.pop(context);
                _loadStores(); // إعادة تحميل البيانات لتحديث الرصيد
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('تمت المعاملة')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
  }

  double _toSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '').replaceAll(' ', '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('الشهر:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedMonth,
                items: _months
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedMonth = v);
                  if (_selectedYear != null) _loadMonthlyPurchases();
                },
              ),
              const SizedBox(width: 16),
              const Text('السنة:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                items: _years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedYear = v);
                  if (_selectedMonth != null) _loadMonthlyPurchases();
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadMonthlyPurchases,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _stores.isEmpty
              ? const Center(child: Text('لا توجد متاجر'))
              : ListView.builder(
            itemCount: _stores.length,
            itemBuilder: (context, index) {
              final store = _stores[index];
              final storeId = store['id'] as int;
              final storeName = store['name'] ?? 'بدون اسم';
              final totalPurchases = _toSafeDouble(store['total_purchases']);
              final monthlyPurchases = _monthlyPurchases[storeId] ?? 0.0;
              final balance = _toSafeDouble(store['balance']);
              final balanceColor = balance > 0
                  ? Colors.green
                  : (balance < 0 ? Colors.red : Colors.grey);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ExpansionTile(
                  leading: const Icon(Icons.store, color: Colors.teal),
                  title: Text(storeName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'إجمالي المشتريات (كل الفترات): ${totalPurchases.toStringAsFixed(2)} SYP',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مشتريات الشهر ($_selectedMonth/$_selectedYear): ${monthlyPurchases.toStringAsFixed(2)} SYP',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الرصيد الحالي: ${balance.toStringAsFixed(2)} SYP',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: balanceColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _addTransaction(storeId, storeName, balance),
                                icon: const Icon(Icons.account_balance_wallet),
                                label: const Text('إضافة دفعة / خصم'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF54d4dd)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}