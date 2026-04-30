// lib/screens/accountant/accountant_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';
import '../../cubits/auth_cubit.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

// ===================== الثوابت والألوان =====================
const Color _primaryColor = Color(0xFF54d4dd);

double _toSafeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// ===================== الصفحة الرئيسية للمحاسب =====================
class AccountantDashboard extends StatefulWidget {
  const AccountantDashboard({super.key});

  @override
  State<AccountantDashboard> createState() => _AccountantDashboardState();
}

class _AccountantDashboardState extends State<AccountantDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<AuthCubit>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الخروج: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة المحاسب',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: _primaryColor),
              tooltip: 'تسجيل خروج',
              onPressed: () => _logout(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: _primaryColor.withOpacity(0.3),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, _primaryColor.withOpacity(0.15)],
            ),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: _primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: _primaryColor,
                tabs: const [
                  Tab(text: 'الزبائن', icon: Icon(Icons.people)),
                  Tab(text: 'السائقين', icon: Icon(Icons.local_taxi)),
                  Tab(text: 'المتاجر', icon: Icon(Icons.store)),
                  Tab(text: 'مشتريات المتاجر', icon: Icon(Icons.shopping_cart)),
                  Tab(text: 'الدفعات', icon: Icon(Icons.receipt)),
                ],
              ),
              Expanded(
                child: BlocProvider<AccountingCubit>(
                  create: (context) => AccountingCubit(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      CustomersBalanceTab(api: _api),
                      DriversBalanceTab(api: _api),
                      StoresBalanceTab(api: _api),
                      StorePurchasesTab(api: _api),
                      TransactionsTab(api: _api),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== تبويب الزبائن =====================
class CustomersBalanceTab extends StatefulWidget {
  final ApiService api;
  const CustomersBalanceTab({super.key, required this.api});

  @override
  State<CustomersBalanceTab> createState() => _CustomersBalanceTabState();
}

class _CustomersBalanceTabState extends State<CustomersBalanceTab> {
  @override
  void initState() {
    super.initState();
    context.read<AccountingCubit>().loadCustomersBalance();
  }

  Future<void> _addPayment(int customerId, String name) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isPayment = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة معاملة لـ $name'),
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
              decoration: const InputDecoration(labelText: 'المبلغ', prefixText: 'ل.س '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
                );
                return;
              }
              final transactionType = isPayment ? 'customer_credit' : 'customer_debit';
              try {
                await context.read<AccountingCubit>().createTransaction({
                  'type': transactionType,
                  'amount': amount,
                  'notes': notesCtrl.text,
                  'customer_id': customerId,
                });
                Navigator.pop(context);
                await context.read<AccountingCubit>().loadCustomersBalance();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is CustomersBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadCustomersBalance(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.customers.length,
              itemBuilder: (_, i) {
                final c = state.customers[i];
                final name = c['name'] ?? 'زبون ${c['id']}';
                final totalBalance = _toSafeDouble(c['balance']);
                final ordersDebt = _toSafeDouble(c['orders_debt']);
                final id = c['id'] as int;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الرصيد: ${totalBalance.toStringAsFixed(2)} ل.س'),
                        if (ordersDebt != 0)
                          Text(
                            '  (ديون طلبات: ${ordersDebt.toStringAsFixed(2)} ل.س)',
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: 'إضافة دفعة / خصم',
                          onPressed: () => _addPayment(id, name),
                        ),
                        Icon(
                          totalBalance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: totalBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}

// ===================== تبويب السائقين =====================
class DriversBalanceTab extends StatefulWidget {
  final ApiService api;
  const DriversBalanceTab({super.key, required this.api});

  @override
  State<DriversBalanceTab> createState() => _DriversBalanceTabState();
}

class _DriversBalanceTabState extends State<DriversBalanceTab> {
  @override
  void initState() {
    super.initState();
    context.read<AccountingCubit>().loadDriversBalance();
  }

  Future<void> _addPayment(int driverId, String name) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isPayment = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة معاملة لـ $name'),
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
              decoration: const InputDecoration(labelText: 'المبلغ', prefixText: 'ل.س '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
                );
                return;
              }
              final transactionType = isPayment ? 'driver_credit' : 'driver_debit';
              try {
                await context.read<AccountingCubit>().createTransaction({
                  'type': transactionType,
                  'amount': amount,
                  'notes': notesCtrl.text,
                  'driver_id': driverId,
                });
                Navigator.pop(context);
                await context.read<AccountingCubit>().loadDriversBalance();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is DriversBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadDriversBalance(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.drivers.length,
              itemBuilder: (_, i) {
                final d = state.drivers[i];
                final name = d['name'] ?? 'سائق ${d['id']}';
                final balance = _toSafeDouble(d['commission_balance']);
                final commission = _toSafeDouble(d['commission_percentage']);
                final id = d['id'] as int;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.local_taxi, color: Colors.teal),
                    title: Text(name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                        Text('العمولة: ${commission.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: 'إضافة دفعة / خصم',
                          onPressed: () => _addPayment(id, name),
                        ),
                        Icon(
                          balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}

// ===================== تبويب المتاجر =====================
class StoresBalanceTab extends StatefulWidget {
  final ApiService api;
  const StoresBalanceTab({super.key, required this.api});

  @override
  State<StoresBalanceTab> createState() => _StoresBalanceTabState();
}

class _StoresBalanceTabState extends State<StoresBalanceTab> {
  @override
  void initState() {
    super.initState();
    context.read<AccountingCubit>().loadStoresBalance();
  }

  Future<void> _addPayment(int storeId, String name) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isPayment = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة معاملة لـ $name'),
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
              decoration: const InputDecoration(labelText: 'المبلغ', prefixText: 'ل.س '),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
                );
                return;
              }
              final transactionType = isPayment ? 'store_credit' : 'store_debit';
              try {
                await context.read<AccountingCubit>().createTransaction({
                  'type': transactionType,
                  'amount': amount,
                  'notes': notesCtrl.text,
                  'store_id': storeId,
                });
                Navigator.pop(context);
                await context.read<AccountingCubit>().loadStoresBalance();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e')),
                );
              }
            },
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is StoresBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadStoresBalance(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.stores.length,
              itemBuilder: (_, i) {
                final s = state.stores[i];
                final name = s['name'] ?? 'متجر ${s['id']}';
                final balance = _toSafeDouble(s['balance']);
                final id = s['id'] as int;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.teal),
                    title: Text(name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: 'إضافة دفعة / خصم',
                          onPressed: () => _addPayment(id, name),
                        ),
                        Icon(
                          balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}

// ===================== تبويب مشتريات المتاجر =====================
class StorePurchasesTab extends StatefulWidget {
  final ApiService api;
  const StorePurchasesTab({super.key, required this.api});

  @override
  State<StorePurchasesTab> createState() => _StorePurchasesTabState();
}

class _StorePurchasesTabState extends State<StorePurchasesTab> {
  @override
  void initState() {
    super.initState();
    context.read<AccountingCubit>().loadStorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is StorePurchasesLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadStorePurchases(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.purchases.length,
              itemBuilder: (_, i) {
                final s = state.purchases[i];
                final name = s['name'] ?? 'متجر ${s['id']}';
                final total = _toSafeDouble(s['total_purchases']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                    title: Text(name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Text('إجمالي المشتريات: ${total.toStringAsFixed(2)} ل.س'),
                    trailing: Icon(
                      total > 0 ? Icons.trending_up : Icons.trending_flat,
                      color: total > 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}

// ===================== تبويب الدفعات (المعاملات) =====================
class TransactionsTab extends StatefulWidget {
  final ApiService api;
  const TransactionsTab({super.key, required this.api});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _isLoadingMore = false;
    }
    await context.read<AccountingCubit>().loadTransactions(page: _currentPage, type: _selectedFilter);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<AccountingCubit>().state;
      if (state is TransactionsLoaded && state.hasMore && !_isLoadingMore) {
        _isLoadingMore = true;
        _currentPage++;
        context.read<AccountingCubit>().loadTransactions(page: _currentPage, type: _selectedFilter).then((_) {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _addTransaction() async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedParty;
    int? selectedId;
    String? transactionType;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة معاملة جديدة'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'الطرف'),
                    items: const [
                      DropdownMenuItem(value: 'customer', child: Text('زبون')),
                      DropdownMenuItem(value: 'driver', child: Text('سائق')),
                      DropdownMenuItem(value: 'store', child: Text('متجر')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedParty = value;
                        selectedId = null;
                        transactionType = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedParty != null)
                    FutureBuilder<List<dynamic>>(
                      future: _fetchOptions(selectedParty),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(labelText: 'اختر ${selectedParty == 'customer' ? 'الزبون' : selectedParty == 'driver' ? 'السائق' : 'المتجر'}'),
                          items: snapshot.data!.map<DropdownMenuItem<int>>((item) {
                            String name = item['name'] ?? item['full_name'] ?? 'غير محدد';
                            return DropdownMenuItem<int>(
                              value: item['id'] as int,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) => selectedId = value,
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  if (selectedParty != null && selectedId != null)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'نوع المعاملة'),
                      items: [
                        if (selectedParty == 'customer')
                          const DropdownMenuItem(value: 'customer_credit', child: Text('دفعة من الزبون (إيداع) ➕')),
                        if (selectedParty == 'customer')
                          const DropdownMenuItem(value: 'customer_debit', child: Text('خصم من الزبون (فاتورة جديدة) ➖')),
                        if (selectedParty == 'driver')
                          const DropdownMenuItem(value: 'driver_credit', child: Text('دفعة للسائق (إيداع) ➕')),
                        if (selectedParty == 'driver')
                          const DropdownMenuItem(value: 'driver_debit', child: Text('خصم من السائق (استرداد) ➖')),
                        if (selectedParty == 'store')
                          const DropdownMenuItem(value: 'store_credit', child: Text('دفعة للمتجر (إيداع) ➕')),
                        if (selectedParty == 'store')
                          const DropdownMenuItem(value: 'store_debit', child: Text('خصم من المتجر (استرداد) ➖')),
                      ],
                      onChanged: (value) => transactionType = value,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'المبلغ', prefixText: 'ل.س '),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات')),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedParty == null || selectedId == null || transactionType == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
                return;
              }
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('المبلغ غير صحيح')));
                return;
              }
              final data = {
                'type': transactionType,
                'amount': amount,
                'notes': notesCtrl.text,
              };
              if (selectedParty == 'customer') data['customer_id'] = selectedId;
              else if (selectedParty == 'driver') data['driver_id'] = selectedId;
              else data['store_id'] = selectedId;

              try {
                await context.read<AccountingCubit>().createTransaction(data);
                Navigator.pop(ctx);
                await _loadTransactions(refresh: true);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')));
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchOptions(String? type) async {
    if (type == 'customer') return widget.api.getCustomers();
    if (type == 'driver') return widget.api.getDrivers();
    if (type == 'store') return widget.api.getStores();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is TransactionsLoaded) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة معاملة جديدة'),
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadTransactions(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.transactions.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final t = state.transactions[index];
                      final isCredit = t['type']?.toString().contains('credit') == true;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Icon(
                            isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                          title: Text('${t['type']} - ${_toSafeDouble(t['amount']).toStringAsFixed(2)} ل.س'),
                          subtitle: Text('${t['notes'] ?? ''} - ${t['created_at']}'),
                          trailing: t['customer_id'] != null
                              ? const Icon(Icons.person, color: Colors.orange)
                              : t['driver_id'] != null
                              ? const Icon(Icons.local_taxi, color: Colors.blue)
                              : const Icon(Icons.store, color: Colors.purple),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}