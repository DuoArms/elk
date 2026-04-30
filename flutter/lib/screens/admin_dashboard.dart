import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/order_cubit.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'add_edit_customer_screen.dart';
import '../models/customer.dart';
import '../models/customer_phone.dart';
import '../models/address.dart';
import 'order_details_screen.dart';
import '../models/order.dart';
import '../cubits/accounting_cubit.dart';
import '../cubits/accounting_state.dart';

// ===================== دوال مساعدة آمنة =====================
double _toSafeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    String cleaned = value.trim().replaceAll(',', '').replaceAll(' ', '');
    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceFirst(',', '.');
    }
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

String _toSafeString(dynamic value) => value?.toString() ?? '0';

const Color _primaryColor = Color(0xFF54d4dd);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AuthCubit>().logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم المدير',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: _primaryColor.withOpacity(0.3),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل خروج',
              color: _primaryColor,
            ),
          ],
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
                  Tab(text: 'الرئيسية', icon: Icon(Icons.dashboard)),
                  Tab(text: 'السائقين', icon: Icon(Icons.local_taxi)),
                  Tab(text: 'موظفي المكتب', icon: Icon(Icons.business)),
                  Tab(text: 'الزبائن', icon: Icon(Icons.people)),
                  Tab(text: 'المحاسبة', icon: Icon(Icons.account_balance_wallet)),
                  Tab(text: 'الطلبات', icon: Icon(Icons.receipt)),
                  Tab(text: 'المتاجر والمخزون', icon: Icon(Icons.storefront)),
                ],
              ),
              Expanded(
                child: BlocProvider<OrderCubit>(
                  create: (context) => OrderCubit(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      HomeTab(api: _api),
                      DriversTab(api: _api),
                      OfficeUsersTab(api: _api),
                      CustomersTab(api: _api),
                      AccountingTab(api: _api),
                      const OrdersManagementContent(),
                      const InventoryAndStoresTab(),
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

// ===================== الصفحة الرئيسية (تم تعديلها لمنع overflow) =====================
class HomeTab extends StatelessWidget {
  final ApiService api;
  const HomeTab({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([api.getAdminStats(), api.getCustomers(), api.getDrivers(), api.getOrders()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final stats = snapshot.data?[0] as Map<String, dynamic>? ?? {};
        final customers = snapshot.data?[1] as List? ?? [];
        final drivers = snapshot.data?[2] as List? ?? [];
        final orders = snapshot.data?[3] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,   // <-- النسبة المعدلة لتوفر مساحة رأسية أكبر
            children: [
              _StatCard(title: 'إجمالي الطلبات', value: orders.length.toString(), icon: Icons.shopping_cart, color: Colors.blue),
              _StatCard(title: 'طلبات اليوم', value: _toSafeString(stats['today_orders']), icon: Icons.today, color: Colors.green),
              _StatCard(title: 'الإيرادات', value: '${_toSafeDouble(stats['total_revenue']).toStringAsFixed(2)} SYP', icon: Icons.attach_money, color: Colors.orange),
              _StatCard(title: 'الزبائن', value: customers.length.toString(), icon: Icons.people, color: Colors.purple),
              _StatCard(title: 'السائقين', value: drivers.length.toString(), icon: Icons.local_taxi, color: Colors.teal),
              _StatCard(title: 'طلبات معلقة', value: _toSafeString(stats['pending_orders']), icon: Icons.pending, color: Colors.red),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------- باقي التبويبات بدون تغيير (ما عدا ما ذكر) ----------------------------
// ... (جميع الكلاسات DriversTab, OfficeUsersTab, CustomersTab, AccountingTab,
//      OrdersManagementContent, InventoryAndStoresTab وتبويباتها الفرعية)
// بنفس الكود السابق دون تعديل ...
// تم حذفها من العرض لتجنب التكرار مع التأكيد أنها موجودة في الملف الأصلي.

// ===================== إدارة السائقين =====================
class DriversTab extends StatefulWidget {
  final ApiService api;
  const DriversTab({super.key, required this.api});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  List<dynamic> _drivers = [];
  bool _loading = true;

  static const List<Map<String, String>> _vehicleTypeOptions = [
    {'label': 'بنزين', 'value': 'petrol'},
    {'label': 'كهرباء', 'value': 'electric'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _loading = true);
    try {
      final drivers = await widget.api.getDrivers();
      setState(() => _drivers = drivers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addDriver() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final commissionCtrl = TextEditingController(text: '10');
    String? selectedVehicleType = 'petrol'; // قيمة افتراضية
    String vehicleOwnership = 'company';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة سائق جديد'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        decoration: const InputDecoration(labelText: 'كلمة المرور'),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedVehicleType,
                        decoration: const InputDecoration(labelText: 'نوع المركبة'),
                        items: _vehicleTypeOptions
                            .map((opt) => DropdownMenuItem(
                          value: opt['value'],
                          child: Text(opt['label']!),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedVehicleType = value);
                        },
                        validator: (value) => value == null ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: vehicleOwnership,
                        decoration: const InputDecoration(labelText: 'ملكية المركبة'),
                        items: const [
                          DropdownMenuItem(value: 'company', child: Text('تابع للشركة')),
                          DropdownMenuItem(value: 'owner', child: Text('مملوكة للسائق')),
                        ],
                        onChanged: (v) {
                          setDialogState(() => vehicleOwnership = v!);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: commissionCtrl,
                        decoration: const InputDecoration(labelText: 'نسبة العمولة (%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await widget.api.createDriver({
                          'full_name': nameCtrl.text,
                          'phone': phoneCtrl.text,
                          'password': passwordCtrl.text,
                          'vehicle_type': selectedVehicleType,   // يجب أن يكون 'petrol' أو 'electric'
                          'vehicle_ownership': vehicleOwnership, // يجب أن يكون 'owner' أو 'company'
                          'commission_percentage': double.tryParse(commissionCtrl.text) ?? 10,
                        });
                        if (!mounted) return;
                        Navigator.pop(context);
                        _loadDrivers();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة السائق')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                      }
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editDriver(dynamic driver) async {
    final user = driver['user'] ?? {};
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final commissionCtrl = TextEditingController(text: _toSafeDouble(driver['commission_percentage']).toString());

    String currentVehicleType = driver['vehicle_type'] ?? '';
    String? selectedVehicleType = _vehicleTypeOptions.any((e) => e['value'] == currentVehicleType) ? currentVehicleType : 'petrol';

    String vehicleOwnership = driver['vehicle_ownership'] ?? 'company';
    if (!['company', 'owner'].contains(vehicleOwnership)) {
      vehicleOwnership = 'company';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تعديل بيانات السائق'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
                    const SizedBox(height: 12),
                    TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      decoration: const InputDecoration(labelText: 'نوع المركبة'),
                      items: _vehicleTypeOptions
                          .map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedVehicleType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: vehicleOwnership,
                      decoration: const InputDecoration(labelText: 'ملكية المركبة'),
                      items: const [
                        DropdownMenuItem(value: 'company', child: Text('تابع للشركة')),
                        DropdownMenuItem(value: 'owner', child: Text('مملوكة للسائق')),
                      ],
                      onChanged: (v) {
                        setDialogState(() => vehicleOwnership = v!);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: commissionCtrl,
                      decoration: const InputDecoration(labelText: 'نسبة العمولة (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    try {
                      await widget.api.updateDriver(driver['id'], {
                        'full_name': nameCtrl.text,
                        'phone': phoneCtrl.text,
                        'vehicle_type': selectedVehicleType,
                        'vehicle_ownership': vehicleOwnership,
                        'commission_percentage': double.tryParse(commissionCtrl.text) ?? 10,
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadDrivers();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDriver(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف السائق "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteDriver(id);
        _loadDrivers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_drivers.isEmpty) return const Center(child: Text('لا يوجد سائقون'));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _addDriver,
            icon: const Icon(Icons.add),
            label: const Text('إضافة سائق'),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _drivers.length,
            itemBuilder: (context, index) {
              final driver = _drivers[index];
              final user = driver['user'] ?? {};
              String vehicleTypeDisplay = '';
              if (driver['vehicle_type'] == 'petrol') vehicleTypeDisplay = 'بنزين';
              else if (driver['vehicle_type'] == 'electric') vehicleTypeDisplay = 'كهرباء';
              else vehicleTypeDisplay = driver['vehicle_type'] ?? 'غير محدد';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: Text(user['full_name'] ?? driver['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text('${user['phone'] ?? ''} - مركبة: $vehicleTypeDisplay - عمولة: ${driver['commission_percentage'] ?? 0}%', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editDriver(driver)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDriver(driver['id'], user['full_name'] ?? 'السائق')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
// ===================== إدارة موظفي المكتب =====================
class OfficeUsersTab extends StatefulWidget {
  final ApiService api;
  const OfficeUsersTab({super.key, required this.api});

  @override
  State<OfficeUsersTab> createState() => _OfficeUsersTabState();
}

class _OfficeUsersTabState extends State<OfficeUsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await widget.api.getOfficeUsers();
      setState(() => _users = users);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOfficeUser() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة موظف مكتب'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true, validator: (v) => v!.isEmpty ? 'مطلوب' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await widget.api.createOfficeUser({
                    'full_name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                    'password': passwordCtrl.text,
                  });
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _editOfficeUser(Map user) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل بيانات مستخدم المكتب'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
              const SizedBox(height: 12),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await widget.api.updateOfficeUser(user['id'], {
                    'full_name': nameCtrl.text,
                    'phone': phoneCtrl.text,
                  });
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOfficeUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف مستخدم المكتب "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteOfficeUser(id);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_users.isEmpty) return const Center(child: Text('لا يوجد موظفين مكتب'));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _addOfficeUser,
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة موظف مكتب'),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.business, color: Colors.green),
                  title: Text(user['full_name'] ?? user['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text(user['phone'] ?? '', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editOfficeUser(user)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteOfficeUser(user['id'], user['full_name'] ?? 'المستخدم')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
class CustomersTab extends StatefulWidget {
  final ApiService api;
  const CustomersTab({super.key, required this.api});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  List<dynamic> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final customers = await widget.api.getCustomers();
      setState(() => _customers = customers);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openCustomerForm({Customer? customer}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditCustomerScreen(customer: customer)),
    );
    if (result == true) _loadCustomers();
  }

  Future<void> _deleteCustomer(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الزبون "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteCustomer(id);
        _loadCustomers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_customers.isEmpty) return const Center(child: Text('لا يوجد زبائن'));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => _openCustomerForm(),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة زبون'),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _customers.length,
            itemBuilder: (context, index) {
              final customerJson = _customers[index];
              final customer = Customer(
                id: customerJson['id'],
                name: customerJson['name'],
                notes: customerJson['notes'],
                balance: _toSafeDouble(customerJson['balance']),
                phones: (customerJson['phones'] as List? ?? []).map((p) => CustomerPhone(phone: p['phone'])).toList(),
                addresses: (customerJson['addresses'] as List? ?? []).map((a) => Address(label: a['label'], addressText: a['address'])).toList(),
                isActive: true,
              );
              return InkWell(
                onTap: () => _openCustomerForm(customer: customer),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: Text(customer.name, style: const TextStyle(color: Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('هاتف: ${customer.phones.isNotEmpty ? customer.phones.first.phone : ''}', style: const TextStyle(color: Colors.black54)),
                        Text('الرصيد: ${customer.balance.toStringAsFixed(2)} SYP', style: TextStyle(color: customer.balance >= 0 ? Colors.green : Colors.red)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openCustomerForm(customer: customer)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCustomer(customer.id, customer.name)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===================== المحاسبة (معدلة مع تبويب الدفعات) =====================
class AccountingTab extends StatefulWidget {
  final ApiService api;
  const AccountingTab({super.key, required this.api});

  @override
  State<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends State<AccountingTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _addPayment(BuildContext context, String type, int id, String name) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isPayment = true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            TextFormField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('المبلغ يجب أن يكون أكبر من صفر')),
                );
                return;
              }
              String transactionType;
              if (type == 'customer') {
                transactionType = isPayment ? 'customer_credit' : 'customer_debit';
              } else if (type == 'driver') {
                transactionType = isPayment ? 'driver_credit' : 'driver_debit';
              } else {
                transactionType = isPayment ? 'store_credit' : 'store_debit';
              }

              final data = {
                'type': transactionType,
                'amount': amount,
                'notes': notesCtrl.text,
              };
              if (type == 'customer') data['customer_id'] = id;
              else if (type == 'driver') data['driver_id'] = id;
              else data['store_id'] = id;

              try {
                await context.read<AccountingCubit>().createTransaction(data);
                Navigator.pop(ctx);
                if (type == 'customer') {
                  context.read<AccountingCubit>().loadCustomersBalance();
                } else if (type == 'driver') {
                  context.read<AccountingCubit>().loadDriversBalance();
                } else {
                  context.read<AccountingCubit>().loadStoresBalance();
                }
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
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
    return BlocProvider<AccountingCubit>(
      create: (_) => AccountingCubit(),
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              TabBar(
                controller: _subTabController,
                labelColor: _primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: _primaryColor,
                tabs: const [
                  Tab(text: 'أرصدة الزبائن', icon: Icon(Icons.people)),
                  Tab(text: 'أرصدة السائقين', icon: Icon(Icons.local_taxi)),
                  Tab(text: 'أرصدة المتاجر', icon: Icon(Icons.store)),
                  Tab(text: 'الدفعات', icon: Icon(Icons.receipt)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _subTabController,
                  children: [
                    // الزبائن
                    BlocBuilder<AccountingCubit, AccountingState>(
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
                                    title: Text(name),
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
                                          onPressed: () => _addPayment(context, 'customer', id, name),
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
                        context.read<AccountingCubit>().loadCustomersBalance();
                        return const SizedBox();
                      },
                    ),
                    // السائقين
                    BlocBuilder<AccountingCubit, AccountingState>(
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
                                    title: Text(name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                                        Text('العمولة: ${commission.toStringAsFixed(2)}%',
                                            style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.green),
                                          onPressed: () => _addPayment(context, 'driver', id, name),
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
                        context.read<AccountingCubit>().loadDriversBalance();
                        return const SizedBox();
                      },
                    ),
                    // المتاجر
                    BlocBuilder<AccountingCubit, AccountingState>(
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
                                    title: Text(name),
                                    subtitle: Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.green),
                                          onPressed: () => _addPayment(context, 'store', id, name),
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
                        context.read<AccountingCubit>().loadStoresBalance();
                        return const SizedBox();
                      },
                    ),
                    // الدفعات (المعاملات)
                    TransactionsTab(api: widget.api),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================== تبويب الدفعات (المعاملات) =====================
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
// ===================== تبويب إدارة الطلبات الجديد =====================
class OrdersManagementContent extends StatefulWidget {
  const OrdersManagementContent({super.key});

  @override
  State<OrdersManagementContent> createState() => _OrdersManagementContentState();
}

class _OrdersManagementContentState extends State<OrdersManagementContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'الكل';
  String _selectedSort = 'الأحدث';

  static const Color primaryColor = Color(0xFF54d4dd);

  final List<String> _statusOptions = [
    'الكل',
    'pending',
    'assigned',
    'accepted',
    'rejected',
    'timeout',
    'on_the_way',
    'items_purchased',
    'delivered',
    'cancelled'
  ];

  final Map<String, String> _statusNames = {
    'pending': 'قيد الانتظار',
    'assigned': 'تم التعيين',
    'accepted': 'تم القبول',
    'rejected': 'مرفوض',
    'timeout': 'انتهى الوقت',
    'on_the_way': 'في الطريق',
    'items_purchased': 'تم شراء الأصناف',
    'delivered': 'تم التوصيل',
    'cancelled': 'ملغي',
  };

  final List<String> _sortOptions = ['الأحدث', 'الأقدم', 'حسب الحالة'];

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                } else if (state is OrdersLoaded) {
                  if (state.filteredOrders.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد طلبات',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.filteredOrders[index];
                      return _OrderCardForAdmin(order: order);
                    },
                  );
                } else if (state is OrderError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<OrderCubit>().loadOrders(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: 'بحث برقم الطلب أو اسم العميل...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            onChanged: (value) {
              context.read<OrderCubit>().searchOrders(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatusFilter,
                  dropdownColor: Colors.white,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'حالة الطلب',
                    labelStyle: TextStyle(color: primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  items: _statusOptions.map((status) {
                    String displayName;
                    if (status == 'الكل') {
                      displayName = 'الكل';
                    } else {
                      displayName = _statusNames[status] ?? status;
                    }
                    return DropdownMenuItem(
                      value: status,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatusFilter = value!;
                    });
                    final statusForFilter = value == 'الكل' ? null : value;
                    context.read<OrderCubit>().filterByStatus(statusForFilter);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSort,
                  dropdownColor: Colors.white,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'ترتيب حسب',
                    labelStyle: TextStyle(color: primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  items: _sortOptions.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    String sortBy;
                    if (value == 'الأحدث') sortBy = 'newest';
                    else if (value == 'الأقدم') sortBy = 'oldest';
                    else sortBy = 'status';
                    context.read<OrderCubit>().sortOrders(sortBy);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// بطاقة عرض الطلب الخاصة بلوحة تحكم المدير (تفتح OrderDetailsScreen)
class _OrderCardForAdmin extends StatelessWidget {
  final Order order;
  const _OrderCardForAdmin({required this.order});

  static const Color primaryColor = Color(0xFF54d4dd);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'timeout': return Colors.grey;
      case 'on_the_way': return Colors.purple;
      case 'items_purchased': return Colors.teal;
      case 'delivered': return Colors.green.shade700;
      case 'cancelled': return Colors.red.shade900;
      default: return Colors.grey;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'assigned': return 'تم التعيين';
      case 'accepted': return 'تم القبول';
      case 'rejected': return 'مرفوض';
      case 'timeout': return 'انتهى الوقت';
      case 'on_the_way': return 'في الطريق';
      case 'items_purchased': return 'تم شراء الأصناف';
      case 'delivered': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  String _getDisplayOrderNumber() {
    if (order.orderNumber.isNotEmpty) {
      return order.orderNumber;
    }
    return order.id > 0 ? 'طلب #${order.id}' : 'طلب جديد';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'رقم الطلب: ${_getDisplayOrderNumber()}',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status.name).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(order.status.name)),
                    ),
                    child: Text(
                      _getStatusName(order.status.name),
                      style: TextStyle(
                        color: _getStatusColor(order.status.name),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.customerName != null && order.customerName!.isNotEmpty)
                Text(
                  'العميل: ${order.customerName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                )
              else
                Text(
                  'العميل: غير محدد',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              const SizedBox(height: 4),
              Text(
                'تاريخ الإنشاء: ${_formatDate(order.createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'إجمالي الرسوم: ${order.deliveryFee} ريال',
                style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _infoChip(Icons.payment, 'دفع: ${order.paidAmount} ريال'),
                  _infoChip(Icons.money_off, 'متبقي: ${order.remainingAmount} ريال'),
                  if (order.items.isNotEmpty)
                    _infoChip(Icons.shopping_bag, 'عدد الأصناف: ${order.items.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ===================== التبويب الجديد: إدارة المخزون والمتاجر =====================
class InventoryAndStoresTab extends StatefulWidget {
  const InventoryAndStoresTab({super.key});

  @override
  State<InventoryAndStoresTab> createState() => _InventoryAndStoresTabState();
}

class _InventoryAndStoresTabState extends State<InventoryAndStoresTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          isScrollable: true,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: _primaryColor,
          tabs: const [
            Tab(text: 'الوحدات', icon: Icon(Icons.scale)),
            Tab(text: 'القياسات', icon: Icon(Icons.straighten)),
            Tab(text: 'المنتجات', icon: Icon(Icons.inventory)),
            Tab(text: 'أنواع المتاجر', icon: Icon(Icons.category)),
            Tab(text: 'المتاجر', icon: Icon(Icons.store)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              UnitsTab(api: _api),
              SizesTab(api: _api),
              ProductsTab(api: _api),
              StoreTypesTab(api: _api),
              StoresTab(api: _api),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------- 1. الوحدات -----------------------------
class UnitsTab extends StatefulWidget {
  final ApiService api;
  const UnitsTab({super.key, required this.api});

  @override
  State<UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<UnitsTab> {
  List<dynamic> _items = [];
  List<dynamic> _storeTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreTypes();
    _load();
  }

  Future<void> _loadStoreTypes() async {
    try {
      final types = await widget.api.getStoreTypes();
      setState(() => _storeTypes = types);
    } catch (e) {
      print('خطأ في تحميل أنواع المتاجر: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getUnits();
      setState(() => _items = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    int? selectedStoreTypeId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة وحدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الوحدة'), autofocus: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'نوع المتجر (اختياري)'),
              hint: const Text('اختر نوع المتجر'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                ..._storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )),
              ],
              onChanged: (value) => selectedStoreTypeId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.createUnit({
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['name']);
    int? selectedStoreTypeId = item['store_type_id'] as int?;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الوحدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الوحدة')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'نوع المتجر (اختياري)'),
              hint: const Text('اختر نوع المتجر'),
              value: selectedStoreTypeId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                ..._storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )),
              ],
              onChanged: (value) => selectedStoreTypeId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.updateUnit(item['id'], {
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف الوحدة "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteUnit(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_items.isEmpty) return const Center(child: Text('لا توجد وحدات'));
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة وحدة'), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white))),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              String storeTypeName = '';
              if (item['store_type_id'] != null) {
                final found = _storeTypes.firstWhere((t) => t['id'] == item['store_type_id'], orElse: () => null);
                if (found != null) storeTypeName = found['name'] as String;
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.scale, color: Colors.blue),
                  title: Text(item['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text('نوع المتجر: ${storeTypeName.isNotEmpty ? storeTypeName : 'غير محدد'}', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'], item['name'] ?? 'الوحدة')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------- 2. القياسات -----------------------------
class SizesTab extends StatefulWidget {
  final ApiService api;
  const SizesTab({super.key, required this.api});

  @override
  State<SizesTab> createState() => _SizesTabState();
}

class _SizesTabState extends State<SizesTab> {
  List<dynamic> _items = [];
  List<dynamic> _storeTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreTypes();
    _load();
  }

  Future<void> _loadStoreTypes() async {
    try {
      final types = await widget.api.getStoreTypes();
      setState(() => _storeTypes = types);
    } catch (e) {
      print('خطأ في تحميل أنواع المتاجر: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getSizes();
      setState(() => _items = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    int? selectedStoreTypeId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قياس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم القياس'), autofocus: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'نوع المتجر (اختياري)'),
              hint: const Text('اختر نوع المتجر'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                ..._storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )),
              ],
              onChanged: (value) => selectedStoreTypeId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.createSize({
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['name']);
    int? selectedStoreTypeId = item['store_type_id'] as int?;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل القياس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم القياس')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'نوع المتجر (اختياري)'),
              hint: const Text('اختر نوع المتجر'),
              value: selectedStoreTypeId,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                ..._storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )),
              ],
              onChanged: (value) => selectedStoreTypeId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.updateSize(item['id'], {
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف القياس "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteSize(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_items.isEmpty) return const Center(child: Text('لا توجد قياسات'));
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة قياس'), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white))),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              String storeTypeName = '';
              if (item['store_type_id'] != null) {
                final found = _storeTypes.firstWhere((t) => t['id'] == item['store_type_id'], orElse: () => null);
                if (found != null) storeTypeName = found['name'] as String;
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.straighten, color: Colors.blue),
                  title: Text(item['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text('نوع المتجر: ${storeTypeName.isNotEmpty ? storeTypeName : 'غير محدد'}', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'], item['name'] ?? 'القياس')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------- 3. المنتجات -----------------------------
class ProductsTab extends StatefulWidget {
  final ApiService api;
  const ProductsTab({super.key, required this.api});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<dynamic> _items = [];
  List<dynamic> _storeTypes = [];
  List<dynamic> _units = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreTypes();
    _loadUnits();
    _load();
  }

  Future<void> _loadStoreTypes() async {
    try {
      final types = await widget.api.getStoreTypes();
      setState(() => _storeTypes = types);
    } catch (e) {
      print('خطأ في تحميل أنواع المتاجر: $e');
    }
  }

  Future<void> _loadUnits() async {
    try {
      final units = await widget.api.getUnits();
      setState(() => _units = units);
    } catch (e) {
      print('خطأ في تحميل الوحدات: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getProducts();
      setState(() => _items = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    int? selectedStoreTypeId;
    int? selectedUnitId;
    final priceCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج'), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'نوع المتجر *'),
                hint: const Text('اختر نوع المتجر'),
                items: _storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )).toList(),
                onChanged: (value) => selectedStoreTypeId = value,
                validator: (value) => value == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'الوحدة (اختياري)'),
                hint: const Text('اختر الوحدة'),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                  ..._units.map((unit) => DropdownMenuItem<int>(
                    value: unit['id'] as int,
                    child: Text(unit['name'] as String),
                  )),
                ],
                onChanged: (value) => selectedUnitId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedStoreTypeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع المتجر مطلوب')));
                return;
              }
              try {
                await widget.api.createProduct({
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                  'unit_id': selectedUnitId,
                  'price': double.tryParse(priceCtrl.text),
                  'is_active': true,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['name']);
    int? selectedStoreTypeId = item['store_type_id'] as int?;
    int? selectedUnitId = item['unit_id'] as int?;
    final priceCtrl = TextEditingController(text: item['price']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المنتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'نوع المتجر *'),
                value: selectedStoreTypeId,
                items: _storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )).toList(),
                onChanged: (value) => selectedStoreTypeId = value,
                validator: (value) => value == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'الوحدة (اختياري)'),
                value: selectedUnitId,
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('بدون')),
                  ..._units.map((unit) => DropdownMenuItem<int>(
                    value: unit['id'] as int,
                    child: Text(unit['name'] as String),
                  )),
                ],
                onChanged: (value) => selectedUnitId = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedStoreTypeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع المتجر مطلوب')));
                return;
              }
              try {
                await widget.api.updateProduct(item['id'], {
                  'name': nameCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                  'unit_id': selectedUnitId,
                  'price': double.tryParse(priceCtrl.text),
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف المنتج "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteProduct(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_items.isEmpty) return const Center(child: Text('لا توجد منتجات'));
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة منتج'), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white))),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              String storeTypeName = '';
              if (item['store_type_id'] != null) {
                final found = _storeTypes.firstWhere((t) => t['id'] == item['store_type_id'], orElse: () => null);
                if (found != null) storeTypeName = found['name'] as String;
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.inventory, color: Colors.blue),
                  title: Text(item['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text('النوع: $storeTypeName - السعر: ${item['price'] ?? 0}', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'], item['name'] ?? 'المنتج')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------- 4. أنواع المتاجر -----------------------------
class StoreTypesTab extends StatefulWidget {
  final ApiService api;
  const StoreTypesTab({super.key, required this.api});

  @override
  State<StoreTypesTab> createState() => _StoreTypesTabState();
}

class _StoreTypesTabState extends State<StoreTypesTab> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getStoreTypes();
      setState(() => _items = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نوع متجر'),
        content: TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم النوع'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.createStoreType({'name': nameCtrl.text});
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['name']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل نوع المتجر'),
        content: TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم النوع')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await widget.api.updateStoreType(item['id'], {'name': nameCtrl.text});
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف نوع المتجر "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteStoreType(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_items.isEmpty) return const Center(child: Text('لا توجد أنواع للمتاجر'));
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة نوع متجر'), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white))),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.category, color: Colors.blue),
                  title: Text(item['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'], item['name'] ?? 'النوع')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------- 5. المتاجر -----------------------------
class StoresTab extends StatefulWidget {
  final ApiService api;
  const StoresTab({super.key, required this.api});

  @override
  State<StoresTab> createState() => _StoresTabState();
}
class _StoresTabState extends State<StoresTab> {
  List<dynamic> _items = [];
  List<dynamic> _storeTypes = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoreTypes();
    _load();
  }

  Future<void> _loadStoreTypes() async {
    try {
      final types = await widget.api.getStoreTypes();
      setState(() => _storeTypes = types);
    } catch (e) {
      print('خطأ في تحميل أنواع المتاجر: $e');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final data = await widget.api.getStores();
      setState(() => _items = data);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل المتاجر: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    int? selectedStoreTypeId;
    final commissionCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة متجر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المتجر'), autofocus: true),
              const SizedBox(height: 12),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 12),
              TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'نوع المتجر *'),
                hint: const Text('اختر نوع المتجر'),
                items: _storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )).toList(),
                onChanged: (value) => selectedStoreTypeId = value,
                validator: (value) => value == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commissionCtrl,
                decoration: const InputDecoration(labelText: 'نسبة العمولة (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedStoreTypeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع المتجر مطلوب')));
                return;
              }
              try {
                await widget.api.createStore({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'address': addressCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                  'commission_percentage': double.tryParse(commissionCtrl.text),
                  'is_active': true,
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final nameCtrl = TextEditingController(text: item['name']);
    final phoneCtrl = TextEditingController(text: item['phone'] ?? '');
    final addressCtrl = TextEditingController(text: item['address'] ?? '');
    int? selectedStoreTypeId = item['store_type_id'] as int?;
    final commissionCtrl = TextEditingController(text: item['commission_percentage']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المتجر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المتجر')),
              const SizedBox(height: 12),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 12),
              TextFormField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'نوع المتجر *'),
                value: selectedStoreTypeId,
                items: _storeTypes.map((type) => DropdownMenuItem<int>(
                  value: type['id'] as int,
                  child: Text(type['name'] as String),
                )).toList(),
                onChanged: (value) => selectedStoreTypeId = value,
                validator: (value) => value == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commissionCtrl,
                decoration: const InputDecoration(labelText: 'نسبة العمولة (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedStoreTypeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نوع المتجر مطلوب')));
                return;
              }
              try {
                await widget.api.updateStore(item['id'], {
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'address': addressCtrl.text,
                  'store_type_id': selectedStoreTypeId,
                  'commission_percentage': double.tryParse(commissionCtrl.text),
                });
                Navigator.pop(context);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف المتجر "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await widget.api.deleteStore(id);
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primaryColor));
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('حدث خطأ في تحميل المتاجر', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) return const Center(child: Text('لا توجد متاجر'));
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('إضافة متجر'), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white))),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              String storeTypeName = '';
              if (item['store_type_id'] != null) {
                final found = _storeTypes.firstWhere((t) => t['id'] == item['store_type_id'], orElse: () => null);
                if (found != null) storeTypeName = found['name'] as String;
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.store, color: Colors.blue),
                  title: Text(item['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.black87)),
                  subtitle: Text('النوع: $storeTypeName - هاتف: ${item['phone'] ?? ''} - عمولة: ${item['commission_percentage'] ?? 0}%', style: const TextStyle(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _edit(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(item['id'], item['name'] ?? 'المتجر')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}