import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/customer.dart';
import '../models/address.dart';
import '../models/customer_phone.dart';
import 'add_order_form.dart';
import '../cubits/customer_cubit.dart';
import '../cubits/order_cubit.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _customer;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _primaryPhoneController;
  List<CustomerPhone> _phones = [];
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _nameController = TextEditingController(text: _customer.name);
    _notesController = TextEditingController(text: _customer.notes ?? '');
    _primaryPhoneController = TextEditingController(text: _customer.primaryPhone ?? '');
    _phones = List.from(_customer.phones);
    _addresses = List.from(_customer.addresses);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _primaryPhoneController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    String localName = _customer.name;
    String localPrimaryPhone = _customer.primaryPhone ?? '';
    String localNotes = _customer.notes ?? '';
    List<CustomerPhone> localPhones = List.from(_customer.phones);
    List<Address> localAddresses = List.from(_customer.addresses);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل بيانات الزبون'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: localName,
                        decoration: const InputDecoration(labelText: 'الاسم *'),
                        onChanged: (val) => setDialogState(() => localName = val),
                        validator: (v) => v == null || v.isEmpty ? 'الاسم مطلوب' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: localPrimaryPhone,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف الأساسي *'),
                        keyboardType: TextInputType.phone,
                        onChanged: (val) => setDialogState(() => localPrimaryPhone = val),
                        validator: (v) => v == null || v.isEmpty ? 'الهاتف الأساسي مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('أرقام هواتف إضافية', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...localPhones.asMap().entries.map((entry) {
                        int idx = entry.key;
                        CustomerPhone phone = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: phone.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم الهاتف',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) => setDialogState(() => localPhones[idx] = CustomerPhone(phone: val)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => setDialogState(() => localPhones.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => localPhones.add(CustomerPhone(phone: ''))),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة هاتف إضافي'),
                      ),
                      const SizedBox(height: 16),
                      const Text('العناوين', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...localAddresses.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Address addr = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: addr.label,
                                  decoration: const InputDecoration(labelText: 'تسمية العنوان'),
                                  onChanged: (val) => setDialogState(() => localAddresses[idx] = Address(
                                    id: addr.id, label: val, addressText: addr.addressText,
                                    latitude: addr.latitude, longitude: addr.longitude,
                                  )),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: addr.addressText,
                                  decoration: const InputDecoration(labelText: 'العنوان'),
                                  onChanged: (val) => setDialogState(() => localAddresses[idx] = Address(
                                    id: addr.id, label: addr.label, addressText: val,
                                    latitude: addr.latitude, longitude: addr.longitude,
                                  )),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => setDialogState(() => localAddresses.removeAt(idx)),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('حذف هذا العنوان', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => localAddresses.add(Address(label: '', addressText: ''))),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة عنوان'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: localNotes,
                        decoration: const InputDecoration(labelText: 'ملاحظات'),
                        maxLines: 3,
                        onChanged: (val) => setDialogState(() => localNotes = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updatedCustomer = Customer(
                      id: _customer.id,
                      name: localName.trim(),
                      primaryPhone: localPrimaryPhone.trim(),
                      phones: localPhones.where((p) => p.phone.trim().isNotEmpty).toList(),
                      addresses: localAddresses.where((a) => a.addressText.trim().isNotEmpty).toList(),
                      notes: localNotes.trim().isEmpty ? null : localNotes.trim(),
                      balance: _customer.balance,
                      userId: _customer.userId,
                      isActive: _customer.isActive,
                      createdAt: _customer.createdAt,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري تحديث البيانات...')),
                    );
                    final cubit = context.read<CustomerCubit>();
                    await cubit.updateCustomer(_customer.id, updatedCustomer);
                    if (cubit.state is! CustomerError && mounted) {
                      setState(() {
                        _customer = updatedCustomer;
                        _phones = List.from(updatedCustomer.phones);
                        _addresses = List.from(updatedCustomer.addresses);
                        _nameController.text = updatedCustomer.name;
                        _primaryPhoneController.text = updatedCustomer.primaryPhone ?? '';
                        _notesController.text = updatedCustomer.notes ?? '';
                      });
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث البيانات بنجاح'), backgroundColor: Colors.green),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل التحديث: ${(cubit.state as CustomerError).message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeactivate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعطيل الزبون'),
        content: Text('هل أنت متأكد من تعطيل "${_customer.name}"؟\n\nلن يتم حذف الطلبات، لكن الزبون لن يظهر في قائمة الزبائن. يمكنك إعادة تفعيله لاحقاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              final cubit = context.read<CustomerCubit>();
              await cubit.deactivateCustomer(_customer.id);
              if (cubit.state is! CustomerError && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تعطيل الزبون بنجاح')),
                );
                Navigator.pop(context, true);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل التعطيل: ${(cubit.state as CustomerError).message}')),
                );
              }
            },
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تفعيل الزبون'),
        content: Text('هل أنت متأكد من إعادة تفعيل "${_customer.name}"؟\n\nسيظهر الزبون مرة أخرى في قائمة الزبائن النشطاء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF54d4dd)),
            onPressed: () async {
              Navigator.pop(ctx);
              final cubit = context.read<CustomerCubit>();
              await cubit.reactivateCustomer(_customer.id);
              if (cubit.state is! CustomerError && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إعادة تفعيل الزبون بنجاح')),
                );
                Navigator.pop(context, true);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل إعادة التفعيل: ${(cubit.state as CustomerError).message}')),
                );
              }
            },
            child: const Text('إعادة تفعيل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPhone = _customer.primaryPhone ?? 'لا يوجد';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_customer.name),
          backgroundColor: const Color(0xFF54d4dd),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_customer.isActive ? Icons.block : Icons.restore),
              onPressed: _customer.isActive ? _confirmDeactivate : _confirmReactivate,
              tooltip: _customer.isActive ? 'تعطيل' : 'تفعيل',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showEditDialog,
              tooltip: 'تعديل',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(primaryPhone),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'أرقام هواتف إضافية',
                icon: Icons.phone_android,
                children: _customer.phones.isEmpty
                    ? [const Text('لا توجد أرقام إضافية مسجلة')]
                    : _customer.phones.map((phone) => ListTile(
                  leading: const Icon(Icons.phone, color: Color(0xFF54d4dd)),
                  title: Text(phone.phone),
                )).toList(),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'العناوين',
                icon: Icons.location_on,
                children: _customer.addresses.isEmpty
                    ? [const Text('لا توجد عناوين مسجلة')]
                    : _customer.addresses.map((address) => ListTile(
                  leading: const Icon(Icons.location_on, color: Color(0xFF54d4dd)),
                  title: Text(address.addressText),
                  subtitle: Text(address.label),
                )).toList(),
              ),
              if (_customer.notes != null && _customer.notes!.isNotEmpty) const SizedBox(height: 16),
              if (_customer.notes != null && _customer.notes!.isNotEmpty)
                _buildSectionCard(
                  title: 'ملاحظات',
                  icon: Icons.note,
                  children: [Padding(padding: const EdgeInsets.all(16), child: Text(_customer.notes!))],
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddOrderForm(customer: _customer)),
            );
            if (result == true && mounted) {
              context.read<OrderCubit>().loadOrders();
            }
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('طلب جديد'),
          backgroundColor: const Color(0xFF54d4dd),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String primaryPhone) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF54d4dd).withOpacity(0.2),
                  child: Text(
                    _customer.name.isNotEmpty ? _customer.name[0] : '?',
                    style: const TextStyle(fontSize: 28, color: Color(0xFF54d4dd), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _customer.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _customer.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(color: _customer.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'رقم الهاتف الأساسي', primaryPhone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.account_balance_wallet, 'الرصيد', '${_customer.balance.toStringAsFixed(2)} ل.س'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'تاريخ الإضافة',
              _customer.createdAt != null
                  ? '${_customer.createdAt!.year}-${_customer.createdAt!.month}-${_customer.createdAt!.day}'
                  : 'غير متوفر',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF54d4dd)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ]),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}