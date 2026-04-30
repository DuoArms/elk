import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/customer_cubit.dart';
import '../models/customer.dart';
import '../models/customer_phone.dart';
import '../models/address.dart';
import '../services/api_service.dart';

const Color _primaryColor = Color(0xFF54d4dd);

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;
  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController(); // الاسم الكامل (سيُستخدم لـ full_name و name)
  final _primaryPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _balanceController = TextEditingController();

  final List<TextEditingController> _phoneControllers = [];
  final List<TextEditingController> _addressTextControllers = [];
  final List<TextEditingController> _addressLabelControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addPhoneField();
    _addAddressField();

    if (widget.customer != null) {
      final c = widget.customer!;
      _fullNameController.text = c.name; // نستخدم name كاسم كامل
      _primaryPhoneController.text = c.primaryPhone ?? '';
      _notesController.text = c.notes ?? '';
      _balanceController.text = c.balance.toString();
      _phoneControllers.clear();
      _addressTextControllers.clear();
      _addressLabelControllers.clear();
      for (var phone in c.phones) {
        final controller = TextEditingController(text: phone.phone);
        _phoneControllers.add(controller);
      }
      for (var addr in c.addresses) {
        final textController = TextEditingController(text: addr.addressText);
        final labelController = TextEditingController(text: addr.label);
        _addressTextControllers.add(textController);
        _addressLabelControllers.add(labelController);
      }
      if (_phoneControllers.isEmpty) _addPhoneField();
      if (_addressTextControllers.isEmpty) _addAddressField();
      setState(() {});
    }
  }

  void _addPhoneField() {
    _phoneControllers.add(TextEditingController());
    setState(() {});
  }

  void _removePhoneField(int index) {
    _phoneControllers[index].dispose();
    _phoneControllers.removeAt(index);
    setState(() {});
  }

  void _addAddressField() {
    _addressTextControllers.add(TextEditingController());
    _addressLabelControllers.add(TextEditingController(text: 'رئيسي'));
    setState(() {});
  }

  void _removeAddressField(int index) {
    _addressTextControllers[index].dispose();
    _addressLabelControllers[index].dispose();
    _addressTextControllers.removeAt(index);
    _addressLabelControllers.removeAt(index);
    setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _primaryPhoneController.dispose();
    _notesController.dispose();
    _balanceController.dispose();
    for (var c in _phoneControllers) c.dispose();
    for (var c in _addressTextControllers) c.dispose();
    for (var c in _addressLabelControllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cubit = context.read<CustomerCubit>();

      final primaryPhone = _primaryPhoneController.text.trim();
      if (primaryPhone.isEmpty) {
        throw 'رقم الهاتف الأساسي مطلوب';
      }

      final name = _fullNameController.text.trim(); // الاسم الكامل
      if (name.isEmpty) {
        throw 'الاسم الكامل مطلوب';
      }

      final additionalPhones = _phoneControllers
          .map((c) => c.text.trim())
          .where((phone) => phone.isNotEmpty)
          .map((phone) => {'phone': phone})
          .toList();

      final addresses = <Map<String, dynamic>>[];
      for (int i = 0; i < _addressTextControllers.length; i++) {
        final text = _addressTextControllers[i].text.trim();
        if (text.isNotEmpty) {
          final label = _addressLabelControllers[i].text.trim();
          addresses.add({
            'address': text,
            'label': label.isEmpty ? 'رئيسي' : label,
          });
        }
      }

      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

      if (widget.customer == null) {
        // إنشاء زبون جديد
        final payload = {
          'full_name': name,
          'primary_phone': primaryPhone,
          'password': '12345678', // كلمة مرور ثابتة (غير معروضة للمستخدم)
          'name': name, // نفس الاسم الكامل
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'balance': balance,
          'additional_phones': additionalPhones,
          'addresses': addresses,
        };

        final addedCustomer = await cubit.addCustomerWithPayload(payload);
        if (mounted) {
          if (addedCustomer != null) {
            Navigator.pop(context, addedCustomer);
          } else {
            Navigator.pop(context, false);
          }
        }
      } else {
        // تحديث زبون موجود
        final updatedCustomer = Customer(
          id: widget.customer!.id,
          name: name,
          primaryPhone: primaryPhone,
          phones: _phoneControllers
              .map((c) => CustomerPhone(phone: c.text.trim()))
              .where((p) => p.phone.isNotEmpty)
              .toList(),
          addresses: addresses.map((a) => Address(
            label: a['label'] as String,
            addressText: a['address'] as String,
          )).toList(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          balance: balance,
          isActive: widget.customer!.isActive,
        );
        await cubit.updateCustomer(widget.customer!.id, updatedCustomer);
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      String errorMsg = 'فشل الحفظ';
      if (e is ApiException) {
        errorMsg = '${e.message}';
        if (e.rawBody != null && e.rawBody!.isNotEmpty) {
          errorMsg += '\n\n${e.rawBody}';
        }
      } else {
        errorMsg = e.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, maxLines: 8),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.customer == null ? 'إضافة زبون جديد' : 'تعديل بيانات الزبون',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 24,
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
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, _primaryColor.withOpacity(0.15)],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // الاسم الكامل (يحل محل الاسم الكامل والاسم المختصر معاً)
                TextFormField(
                  controller: _fullNameController,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل *',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.person, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الاسم الكامل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _primaryPhoneController,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف الأساسي *',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.phone_android, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'الهاتف الأساسي مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _balanceController,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'الرصيد (اختياري)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.account_balance_wallet, color: _primaryColor),
                    hintText: '0.0',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                const Text(
                  'أرقام هواتف إضافية (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ..._phoneControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            style: TextStyle(color: Colors.grey[800]),
                            decoration: InputDecoration(
                              labelText: 'رقم إضافي ${index + 1}',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                              ),
                              prefixIcon: Icon(Icons.phone, color: _primaryColor),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePhoneField(index),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addPhoneField,
                    icon: Icon(Icons.add, color: _primaryColor),
                    label: Text('إضافة رقم هاتف إضافي', style: TextStyle(color: _primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'العناوين (اختياري)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ..._addressTextControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final textController = entry.value;
                  final labelController = _addressLabelControllers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: textController,
                                  style: TextStyle(color: Colors.grey[800]),
                                  decoration: InputDecoration(
                                    labelText: 'العنوان',
                                    labelStyle: TextStyle(color: Colors.grey[600]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                                    ),
                                    prefixIcon: Icon(Icons.location_on, color: _primaryColor),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              if (index > 0)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeAddressField(index),
                                )
                              else
                                const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: labelController,
                            style: TextStyle(color: Colors.grey[800]),
                            decoration: InputDecoration(
                              labelText: 'نوع المكان (مثال: منزل، عمل)',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                              ),
                              prefixIcon: Icon(Icons.label, color: _primaryColor),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addAddressField,
                    icon: Icon(Icons.add, color: _primaryColor),
                    label: Text('إضافة عنوان آخر', style: TextStyle(color: _primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.note, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('حفظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}