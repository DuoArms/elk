import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

import '../models/customer.dart';
import '../models/customer_phone.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/address.dart';
import '../cubits/order_cubit.dart';
import '../cubits/customer_cubit.dart';
import '../cubits/driver_cubit.dart';
import '../cubits/store_type_cubit.dart';
import '../cubits/store_cubit.dart';
import '../cubits/product_cubit.dart';
import '../cubits/unit_cubit.dart';
import '../cubits/size_cubit.dart';
import '../models/size.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

class StoreType {
  final int id;
  final String name;
  StoreType({required this.id, required this.name});
  factory StoreType.fromJson(Map<String, dynamic> json) => StoreType(id: json['id'], name: json['name']);
}

enum _OrderItemType { product, delivery, invoice }

// ======================= Searchable Dropdown =======================
class SearchableDropdownButton<T> extends StatelessWidget {
  final int? value;
  final List<T> items;
  final void Function(int?) onChanged;
  final String label;
  final String Function(T) displayString;
  final Future<int?> Function(String newName, {required int? parentId, required BuildContext context}) onAddItem;
  final int? parentId;
  final bool requiresParent;

  const SearchableDropdownButton({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    required this.displayString,
    required this.onAddItem,
    this.parentId,
    this.requiresParent = false,
  }) : super(key: key);

  Future<void> _openSearch(BuildContext context) async {
    final selectedId = await showSearch<int?>(
      context: context,
      delegate: _SearchDelegate<T>(
        items: items,
        displayString: displayString,
        onAddItem: (name) async {
          if (requiresParent && parentId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يرجى اختيار نوع المتجر أولاً'), backgroundColor: Colors.orange),
            );
            return null;
          }
          return await onAddItem(name, parentId: parentId, context: context);
        },
        label: label,
        getId: (item) => (item as dynamic).id,
      ),
    );
    if (selectedId != null && selectedId != value) {
      onChanged(selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: AddOrderForm.primaryColor),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AddOrderForm.primaryColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AddOrderForm.primaryColor, width: 2)),
            ),
            value: value,
            items: items.map((item) {
              final id = (item as dynamic).id;
              return DropdownMenuItem<int?>(
                value: id,
                child: Text(displayString(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _openSearch(context),
          color: AddOrderForm.primaryColor,
        ),
      ],
    );
  }
}

class _SearchDelegate<T> extends SearchDelegate<int?> {
  final List<T> items;
  final String Function(T) displayString;
  final Future<int?> Function(String name) onAddItem;
  final String label;
  final int Function(T) getId;

  _SearchDelegate({
    required this.items,
    required this.displayString,
    required this.onAddItem,
    required this.label,
    required this.getId,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((item) => displayString(item).toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(displayString(results[index])),
        onTap: () => close(context, getId(results[index])),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? items
        : items.where((item) => displayString(item).toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: suggestions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text('إضافة $label جديد'),
            onTap: () async {
              final newId = await _showAddDialog(context);
              if (newId != null) close(context, newId);
            },
          );
        }
        final item = suggestions[index - 1];
        return ListTile(
          title: Text(displayString(item)),
          onTap: () => close(context, getId(item)),
        );
      },
    );
  }

  Future<int?> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة $label جديد'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'الاسم'),
            validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final addedId = await onAddItem(nameController.text.trim());
                if (addedId != null) Navigator.pop(ctx, addedId);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

// ======================= Customer Search Delegate (معدل) =======================
class _CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final List<Customer> customers;

  _CustomerSearchDelegate(this.customers);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filterCustomers();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildCustomerTile(context, results[index]),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filterCustomers();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildCustomerTile(context, results[index]),
    );
  }

  List<Customer> _filterCustomers() {
    if (query.isEmpty) return customers;
    final lower = query.toLowerCase();
    return customers.where((c) {
      if (c.name.toLowerCase().contains(lower)) return true;
      if (c.primaryPhone?.toLowerCase().contains(lower) ?? false) return true;
      return c.phones.any((p) => p.phone.contains(lower));
    }).toList();
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    final primaryPhone = customer.primaryPhone ?? (customer.phones.isNotEmpty ? customer.phones.first.phone : '');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AddOrderForm.primaryColor.withOpacity(0.2),
        child: Text(
          customer.name.isNotEmpty ? customer.name[0] : '?',
          style: const TextStyle(color: AddOrderForm.primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(customer.name),
      subtitle: Text(primaryPhone),
      onTap: () => close(context, customer),
    );
  }
}

// ======================= Main Form =======================
class AddOrderForm extends StatefulWidget {
  final Customer? customer;
  final Order? initialOrder;
  static const Color primaryColor = Color(0xFF54d4dd);

  const AddOrderForm({Key? key, this.customer, this.initialOrder}) : super(key: key);

  @override
  State<AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<AddOrderForm> {
  static final RegExp _decimalRegExp = RegExp(r'^\d*\.?\d*$');

  late bool _isEditing;
  Order? _editingOrder;
  int? _originalCustomerId;
  bool _isEditingExistingCustomer = false;
  bool _isLoadingCustomerData = false;
  bool _isInitialDataLoaded = false;

  // --- Customer data for existing customer ---
  late String _customerName;
  List<String> _customerPhones = [];
  List<bool> _selectedPhones = [];
  Address? _selectedAddress;
  List<Address> _customerAddresses = [];

  // --- New customer fields ---
  final TextEditingController _newCustomerNameController = TextEditingController();
  final TextEditingController _primaryPhoneForNewCustomer = TextEditingController();
  final List<TextEditingController> _additionalPhoneControllers = [TextEditingController()];
  final TextEditingController _newAddressController = TextEditingController();
  final TextEditingController _customerNotesController = TextEditingController();

  // --- Driver & payment ---
  int? _selectedDriverId;
  double _deliveryFee = 0.0;
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  PaymentStatus _paymentStatus = PaymentStatus.cash;
  final TextEditingController _paidAmountController = TextEditingController(text: '0');
  final TextEditingController _orderTotalController = TextEditingController();

  // --- Order items ---
  final List<OrderItem> _orderItems = [];
  _OrderItemType _currentItemType = _OrderItemType.product;

  // --- Product fields ---
  int? _selectedStoreTypeId;
  int? _selectedStoreId;
  int? _selectedProductId;
  int? _selectedUnitId;
  int? _selectedSizeId;
  final TextEditingController _productQuantityController = TextEditingController(text: '1');
  final TextEditingController _productDescriptionController = TextEditingController();

  // --- Delivery fields ---
  final TextEditingController _pickupAddressController = TextEditingController();
  final TextEditingController _pickupPhoneController = TextEditingController();
  final TextEditingController _deliveryAddressItemController = TextEditingController();
  final TextEditingController _deliveryPhoneController = TextEditingController();
  final TextEditingController _deliveryDescriptionController = TextEditingController();

  // --- Invoice fields ---
  final TextEditingController _invoiceTypeController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _estimatedTotalController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _invoiceNotesController = TextEditingController();

  bool _isSubmitting = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialOrder != null;
    _editingOrder = widget.initialOrder;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUserId();

    context.read<DriverCubit>().loadDrivers();
    context.read<StoreTypeCubit>().loadStoreTypes();
    context.read<CustomerCubit>().loadCustomers();

    if (widget.customer != null) {
      _isEditingExistingCustomer = true;
      _originalCustomerId = widget.customer!.id;
      _populateFromCustomer(widget.customer!);
    } else if (_isEditing && _editingOrder != null) {
      _isEditingExistingCustomer = true;
      _originalCustomerId = _editingOrder!.customerId;
      await _loadCustomerForEditing();
      _loadDataForOrderItems();
    } else {
      _isEditingExistingCustomer = false;
      _customerName = '';
      _customerAddresses = [];
      _selectedAddress = null;
    }

    setState(() => _isInitialDataLoaded = true);
  }

  Future<void> _loadDataForOrderItems() async {
    for (var item in _orderItems) {
      if (item.itemType == 'product' && item.storeId != null) {
        final storeTypeId = await _getStoreTypeIdForStore(item.storeId!);
        if (storeTypeId != null) {
          context.read<StoreCubit>().loadStores(storeTypeId: storeTypeId);
          context.read<ProductCubit>().loadProducts(storeTypeId: storeTypeId);
          context.read<UnitCubit>().loadUnits(storeTypeId: storeTypeId);
          context.read<SizeCubit>().loadSizes(storeTypeId: storeTypeId);
          break;
        }
      }
    }
  }

  Future<int?> _getStoreTypeIdForStore(int storeId) async {
    final state = context.read<StoreCubit>().state;
    if (state is StoresLoaded) {
      final store = state.stores.firstWhereOrNull((s) => s.id == storeId);
      if (store != null) return store.storeTypeId;
    }
    return null;
  }

  void _populateFromCustomer(Customer customer) {
    _customerName = customer.name;
    List<String> allPhones = [];
    if (customer.primaryPhone != null && customer.primaryPhone!.isNotEmpty) {
      allPhones.add(customer.primaryPhone!);
    }
    allPhones.addAll(customer.phones.map((p) => p.phone));
    _customerPhones = allPhones.toSet().toList();

    _selectedPhones = List.filled(_customerPhones.length, false);
    if (customer.primaryPhone != null && _customerPhones.contains(customer.primaryPhone)) {
      final index = _customerPhones.indexOf(customer.primaryPhone!);
      _selectedPhones[index] = true;
    } else if (_customerPhones.isNotEmpty) {
      _selectedPhones[0] = true;
    }

    _customerAddresses = List.from(customer.addresses);
    if (_customerAddresses.isNotEmpty) {
      _selectedAddress = _customerAddresses.first;
    } else {
      _selectedAddress = null;
    }
  }

  Future<void> _loadCustomerForEditing() async {
    setState(() => _isLoadingCustomerData = true);

    final customerState = context.read<CustomerCubit>().state;
    Customer? customer;

    if (customerState is CustomersLoaded) {
      try {
        customer = customerState.customers.firstWhere(
              (c) => c.id == _originalCustomerId,
        );
      } catch (e) {}
    }

    if (customer == null) {
      final completer = Completer<Customer>();
      final subscription = context.read<CustomerCubit>().stream.listen((state) {
        if (state is CustomersLoaded) {
          final found = state.customers.firstWhere(
                (c) => c.id == _originalCustomerId,
            orElse: () => throw Exception('العميل غير موجود'),
          );
          if (!completer.isCompleted) completer.complete(found);
        } else if (state is CustomerError) {
          if (!completer.isCompleted) completer.completeError(state.message);
        }
      });
      try {
        customer = await completer.future;
      } catch (e) {
        if (mounted) _showError('فشل تحميل بيانات العميل: $e');
        setState(() => _isLoadingCustomerData = false);
        await subscription.cancel();
        return;
      }
      await subscription.cancel();
    }

    if (customer != null && mounted) {
      _populateFromCustomerWithOrder(customer, _editingOrder!);
    }
    setState(() => _isLoadingCustomerData = false);
  }

  void _populateFromCustomerWithOrder(Customer customer, Order order) {
    _populateFromCustomer(customer);
    final orderPhoneList = order.orderPhones?.split(',') ?? [];
    if (orderPhoneList.isNotEmpty) {
      _selectedPhones = _customerPhones.map((phone) => orderPhoneList.contains(phone)).toList();
    }
    _selectedDriverId = order.driverId;
    _deliveryFee = order.deliveryFee;
    _deliveryFeeController.text = _deliveryFee.toString();
    _paymentStatus = order.paymentStatus;
    _paidAmountController.text = order.paidAmount.toString();
    _notesController.text = order.notes ?? '';
    _orderTotalController.text = order.remainingAmount != 0 ? order.remainingAmount.toString() : '';

    _orderItems.clear();
    _orderItems.addAll(order.items);
    _orderItems.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('user_id');
    if (uid == null) {
      try {
        final api = ApiService();
        final me = await api.get('me');
        if (me != null && me['id'] != null) {
          _currentUserId = me['id'];
          await prefs.setInt('user_id', _currentUserId!);
        }
      } catch (e) {
        _showError('لم يتم العثور على معرف المستخدم. الرجاء تسجيل الخروج والدخول مرة أخرى.');
      }
    } else {
      _currentUserId = uid;
    }
  }

  void _removeOrderItem(int index) => setState(() => _orderItems.removeAt(index));

  Future<void> _editOrderItem(int index) async {
    final item = _orderItems[index];
    final updatedItem = await _showEditItemDialog(item);
    if (updatedItem != null) {
      if (updatedItem.itemType == 'product') {
        if (updatedItem.storeName == null && updatedItem.storeId != null) {
          final storeState = context.read<StoreCubit>().state;
          if (storeState is StoresLoaded) {
            final store = storeState.stores.firstWhereOrNull((s) => s.id == updatedItem.storeId);
            updatedItem.storeName = store?.name;
          }
        }
        if (updatedItem.productName == null && updatedItem.productId != null) {
          final productState = context.read<ProductCubit>().state;
          if (productState is ProductsLoaded) {
            final product = productState.products.firstWhereOrNull((p) => p.id == updatedItem.productId);
            updatedItem.productName = product?.name;
          }
        }
        if (updatedItem.unitName == null && updatedItem.unitId != null) {
          final unitState = context.read<UnitCubit>().state;
          if (unitState is UnitsLoaded) {
            final unit = unitState.units.firstWhereOrNull((u) => u.id == updatedItem.unitId);
            updatedItem.unitName = unit?.name;
          }
        }
        if (updatedItem.sizeName == null && updatedItem.sizeId != null) {
          final sizeState = context.read<SizeCubit>().state;
          if (sizeState is SizesLoaded) {
            final size = sizeState.sizes.firstWhereOrNull((sz) => sz.id == updatedItem.sizeId);
            updatedItem.sizeName = size?.name;
          }
        }
      }
      setState(() {
        _orderItems[index] = updatedItem;
      });
      if (_isEditing && _editingOrder != null && updatedItem.id != null && updatedItem.id! > 0) {
        await _updateOrderItemInBackend(updatedItem);
      }
    }
  }

  Future<OrderItem?> _showEditItemDialog(OrderItem item) async {
    if (item.itemType == 'product') {
      return showDialog<OrderItem>(
        context: context,
        builder: (context) => _EditProductDialog(item: item),
      );
    } else if (item.itemType == 'delivery') {
      return showDialog<OrderItem>(
        context: context,
        builder: (context) => _EditDeliveryDialog(item: item),
      );
    } else {
      return showDialog<OrderItem>(
        context: context,
        builder: (context) => _EditInvoiceDialog(item: item),
      );
    }
  }

  Future<void> _updateOrderItemInBackend(OrderItem item) async {
    try {
      final api = ApiService();
      final response = await api.put(
        'orders/${_editingOrder!.id}/items/${item.id}',
        item.toJson(),
      );
      if (response['item'] != null) {
        _showSuccess('تم تحديث العنصر بنجاح');
      }
    } catch (e) {
      _showError('فشل تحديث العنصر: $e');
    }
  }

  // ========== Search and select existing customer ==========
  Future<void> _searchAndSelectCustomer() async {
    final customerState = context.read<CustomerCubit>().state;
    List<Customer> customers = [];
    if (customerState is CustomersLoaded) {
      customers = customerState.customers;
    } else {
      await context.read<CustomerCubit>().loadCustomers();
      final newState = context.read<CustomerCubit>().state;
      if (newState is CustomersLoaded) {
        customers = newState.customers;
      }
    }

    if (customers.isEmpty) {
      _showError('لا يوجد زبائن لعرضها');
      return;
    }

    final selectedCustomer = await showSearch<Customer?>(
      context: context,
      delegate: _CustomerSearchDelegate(customers),
    );

    if (selectedCustomer != null) {
      setState(() {
        _isEditingExistingCustomer = true;
        _originalCustomerId = selectedCustomer.id;
        _populateFromCustomer(selectedCustomer);

        // إذا كان هناك عنوان محدد مسبقاً من الزبون، نستخدمه
        if (_customerAddresses.isNotEmpty && _selectedAddress == null) {
          _selectedAddress = _customerAddresses.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _newCustomerNameController.dispose();
    _primaryPhoneForNewCustomer.dispose();
    for (var c in _additionalPhoneControllers) c.dispose();
    _newAddressController.dispose();
    _customerNotesController.dispose();
    _deliveryFeeController.dispose();
    _notesController.dispose();
    _paidAmountController.dispose();
    _orderTotalController.dispose();
    _productQuantityController.dispose();
    _productDescriptionController.dispose();
    _pickupAddressController.dispose();
    _pickupPhoneController.dispose();
    _deliveryAddressItemController.dispose();
    _deliveryPhoneController.dispose();
    _deliveryDescriptionController.dispose();
    _invoiceTypeController.dispose();
    _companyNameController.dispose();
    _estimatedTotalController.dispose();
    _dueDateController.dispose();
    _invoiceNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialDataLoaded) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_isLoadingCustomerData) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return BlocProvider(
      create: (context) => CustomerCubit()..loadCustomers(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? "تعديل الطلب #${_editingOrder!.orderNumber}" : (_isEditingExistingCustomer ? "طلب جديد لـ $_customerName" : "طلب جديد"),
              style: const TextStyle(
                color: AddOrderForm.primaryColor,
                fontWeight: FontWeight.w900,
                fontFamily: 'OsamaFont',
                fontSize: 28,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const ui.Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AddOrderForm.primaryColor.withOpacity(0.3),
              ),
            ),
            iconTheme: IconThemeData(color: AddOrderForm.primaryColor),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, AddOrderForm.primaryColor.withOpacity(0.15)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOrderItemsSection(),
                const SizedBox(height: 20),
                _buildAddItemSection(),
                const SizedBox(height: 20),
                _buildCustomerSection(),
                const SizedBox(height: 20),
                _buildDriverAndPaymentSection(),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AddOrderForm.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("إرسال الطلب", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== عرض عناصر الطلب مجمعة حسب المتجر ==========
  Widget _buildOrderItemsSection() {
    final productItems = _orderItems.where((item) => item.itemType == 'product').toList();
    final otherItems = _orderItems.where((item) => item.itemType != 'product').toList();

    final Map<int?, List<OrderItem>> groupedProducts = {};
    for (var item in productItems) {
      final storeId = item.storeId;
      if (!groupedProducts.containsKey(storeId)) {
        groupedProducts[storeId] = [];
      }
      groupedProducts[storeId]!.add(item);
    }

    return _sectionContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: AddOrderForm.primaryColor),
                const SizedBox(width: 10),
                Text(
                  "عناصر الطلب",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AddOrderForm.primaryColor, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_orderItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("لا توجد عناصر مضافة", style: TextStyle(color: Colors.grey[600])),
              )
            else
              Column(
                children: [
                  for (var entry in groupedProducts.entries)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.store, size: 18, color: AddOrderForm.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value.first.storeName ?? 'متجر غير معروف',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AddOrderForm.primaryColor),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...entry.value.map((item) => _buildProductItemTile(item)),
                          ],
                        ),
                      ),
                    ),
                  ...otherItems.map((item) => _buildOtherItemTile(item)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemTile(OrderItem item) {
    final index = _orderItems.indexOf(item);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  item.productName ?? 'منتج',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _getProductSubtitle(item),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editOrderItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeOrderItem(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherItemTile(OrderItem item) {
    final index = _orderItems.indexOf(item);
    String titleText;
    if (item.itemType == 'delivery') {
      titleText = 'خدمة توصيل';
    } else {
      titleText = 'فاتورة';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_getItemSubtitle(item), style: const TextStyle(fontSize: 12), maxLines: 4, overflow: TextOverflow.ellipsis),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editOrderItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeOrderItem(index),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductSubtitle(OrderItem item) {
    String details = 'الكمية: ${item.quantity}';
    if (item.unitName != null) details += ' ${item.unitName}';
    if (item.sizeName != null) details += '، القياس: ${item.sizeName}';
    if (item.estimatedPrice != null) details += '، السعر: ${item.estimatedPrice}';
    if (item.description != null && item.description!.isNotEmpty) details += '\n${item.description}';
    return details;
  }

  String _getItemSubtitle(OrderItem item) {
    switch (item.itemType) {
      case 'delivery':
        String details = '';
        if (item.pickupAddress != null) details += 'من: ${item.pickupAddress} ';
        if (item.deliveryAddress != null) details += 'إلى: ${item.deliveryAddress}';
        if (item.estimatedFee != null) details += '، الأجرة: ${item.estimatedFee}';
        if (item.description != null && item.description!.isNotEmpty) details += '\n${item.description}';
        return details;
      case 'invoice':
        String details = '';
        if (item.companyName != null) details += 'الشركة: ${item.companyName}';
        if (item.invoiceType != null && item.invoiceType!.isNotEmpty) details += '، النوع: ${item.invoiceType}';
        if (item.estimatedTotal != null) details += '، المبلغ: ${item.estimatedTotal}';
        if (item.dueDate != null) details += '، الاستحقاق: ${item.dueDate!.toIso8601String().split('T').first}';
        if (item.notes != null && item.notes!.isNotEmpty) details += '\nملاحظات: ${item.notes}';
        return details;
      default:
        return '';
    }
  }

  // ========== قسم بيانات العميل (بعد إزالة البحث القديم وإضافة زر البحث) ==========
  Widget _buildCustomerSection() {
    return _sectionContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AddOrderForm.primaryColor),
                const SizedBox(width: 10),
                Text(
                  "بيانات العميل",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AddOrderForm.primaryColor, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // حقل اسم العميل مع زر البحث (يظهر في الحالتين)
            Row(
              children: [
                Expanded(
                  child: _isEditingExistingCustomer
                      ? TextField(
                    onChanged: (value) => _customerName = value,
                    controller: TextEditingController(text: _customerName),
                    decoration: _inputDecoration("الاسم"),
                    style: TextStyle(color: Colors.grey[800]),
                  )
                      : TextField(
                    controller: _newCustomerNameController,
                    decoration: _inputDecoration("اسم العميل *"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: AddOrderForm.primaryColor),
                  onPressed: _searchAndSelectCustomer,
                  tooltip: 'البحث عن زبون موجود',
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isEditingExistingCustomer) ...[
              // عرض أرقام الهاتف والعناوين للعميل الموجود
              Text(
                "أرقام الهاتف (اختر رقمًا أو أكثر):",
                style: TextStyle(color: AddOrderForm.primaryColor, fontWeight: FontWeight.w500),
              ),
              ..._customerPhones.asMap().entries.map((entry) => CheckboxListTile(
                title: Text(entry.value, style: TextStyle(color: Colors.grey[800])),
                value: _selectedPhones[entry.key],
                onChanged: (v) => setState(() => _selectedPhones[entry.key] = v ?? false),
                activeColor: AddOrderForm.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              )),
              const SizedBox(height: 8),
              Text(
                "عنوان العميل",
                style: TextStyle(fontWeight: FontWeight.bold, color: AddOrderForm.primaryColor),
              ),
              const SizedBox(height: 4),
              if (_customerAddresses.length > 1) ...[
                DropdownButtonFormField<Address>(
                  decoration: _inputDecoration("اختر العنوان *"),
                  value: _selectedAddress,
                  items: _customerAddresses.map((addr) {
                    return DropdownMenuItem<Address>(
                      value: addr,
                      child: Text('${addr.label}: ${addr.addressText}'),
                    );
                  }).toList(),
                  onChanged: (newAddress) {
                    setState(() {
                      _selectedAddress = newAddress;
                    });
                  },
                ),
              ] else if (_customerAddresses.length == 1) ...[
                TextField(
                  controller: TextEditingController(text: _customerAddresses.first.addressText),
                  readOnly: true,
                  decoration: _inputDecoration("العنوان *"),
                ),
              ] else ...[
                TextField(
                  decoration: _inputDecoration("العنوان *"),
                  onChanged: (val) {
                    _selectedAddress = Address(label: '', addressText: val);
                  },
                ),
              ],
            ] else ...[
              // حقول إضافة زبون جديد
              TextField(
                controller: _primaryPhoneForNewCustomer,
                decoration: _inputDecoration("رقم الهاتف الأساسي *"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Text(
                "أرقام هواتف إضافية (اختياري):",
                style: TextStyle(color: AddOrderForm.primaryColor, fontWeight: FontWeight.w500),
              ),
              ..._additionalPhoneControllers.asMap().entries.map((entry) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: _inputDecoration("رقم ${entry.key + 1}"),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  if (entry.key == _additionalPhoneControllers.length - 1)
                    IconButton(
                      icon: Icon(Icons.add_circle, color: AddOrderForm.primaryColor),
                      onPressed: () => setState(() => _additionalPhoneControllers.add(TextEditingController())),
                    ),
                  if (entry.key > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => _additionalPhoneControllers.removeAt(entry.key)),
                    ),
                ],
              )),
              const SizedBox(height: 12),
              TextField(
                controller: _newAddressController,
                decoration: _inputDecoration("عنوان العميل *"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerNotesController,
                decoration: _inputDecoration("ملاحظات عن العميل"),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAndPaymentSection() {
    return _sectionContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_taxi, color: AddOrderForm.primaryColor),
                const SizedBox(width: 10),
                Text(
                  "بيانات التوصيل والدفع",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AddOrderForm.primaryColor, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<DriverCubit, DriverState>(
              builder: (context, state) {
                if (state is DriversLoading) return const Center(child: CircularProgressIndicator());
                if (state is DriversLoaded) {
                  final available = state.drivers.where((d) => d.isAvailable).toList();
                  if (available.isEmpty) return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "⚠️ لا يوجد سائقين متاحين حاليًا",
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  );
                  return DropdownButtonFormField<int>(
                    decoration: _inputDecoration("اختر السائق *"),
                    value: _selectedDriverId,
                    items: available.map<DropdownMenuItem<int>>((d) => DropdownMenuItem<int>(
                      value: d.id,
                      child: Text("${d.fullName ?? 'سائق'} (${d.vehicleType ?? 'غير محدد'})"),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDriverId = v),
                  );
                }
                if (state is DriverError) return Text("خطأ: ${state.message}", style: const TextStyle(color: Colors.red));
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryFeeController,
              decoration: _inputDecoration("أجرة التوصيل *"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
              onChanged: (v) => _deliveryFee = double.tryParse(v) ?? 0.0,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentStatus>(
              value: _paymentStatus,
              items: PaymentStatus.values.map<DropdownMenuItem<PaymentStatus>>((ps) => DropdownMenuItem<PaymentStatus>(
                value: ps,
                child: Text(ps.name == 'cash' ? 'نقداً' : ps.name == 'credit' ? 'دين' : 'جزئي'),
              )).toList(),
              onChanged: (v) => setState(() => _paymentStatus = v!),
              decoration: _inputDecoration("طريقة الدفع"),
            ),
            const SizedBox(height: 12),
            if (_paymentStatus == PaymentStatus.credit) ...[
              TextField(
                controller: _orderTotalController,
                decoration: _inputDecoration("إجمالي الطلب *"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
              ),
              const SizedBox(height: 12),
            ] else if (_paymentStatus == PaymentStatus.partial) ...[
              TextField(
                controller: _orderTotalController,
                decoration: _inputDecoration("قيمة الطلب *"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paidAmountController,
                decoration: _inputDecoration("المبلغ المدفوع *"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _notesController,
              decoration: _inputDecoration("ملاحظات عامة"),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemSection() {
    return _sectionContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_box, color: AddOrderForm.primaryColor),
                const SizedBox(width: 10),
                Text(
                  "إضافة عنصر جديد",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AddOrderForm.primaryColor, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<_OrderItemType>(
              segments: const [
                ButtonSegment(value: _OrderItemType.product, label: Text('منتج')),
                ButtonSegment(value: _OrderItemType.delivery, label: Text('توصيل')),
                ButtonSegment(value: _OrderItemType.invoice, label: Text('فاتورة')),
              ],
              selected: {_currentItemType},
              onSelectionChanged: (s) => setState(() => _currentItemType = s.first),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return Colors.white;
                  return AddOrderForm.primaryColor;
                }),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return AddOrderForm.primaryColor;
                  return Colors.white;
                }),
                side: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) return BorderSide.none;
                  return BorderSide(color: AddOrderForm.primaryColor);
                }),
              ),
            ),
            const SizedBox(height: 20),
            if (_currentItemType == _OrderItemType.product) ..._buildProductFields(),
            if (_currentItemType == _OrderItemType.delivery) ..._buildDeliveryFields(),
            if (_currentItemType == _OrderItemType.invoice) ..._buildInvoiceFields(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addOrderItemFromFields,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("إضافة العنصر"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AddOrderForm.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddButton({
    required String label,
    required String emptyMessage,
    required Future<int?> Function(String name) onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: _inputDecoration(label),
            controller: TextEditingController(text: emptyMessage),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final nameController = TextEditingController();
            final formKey = GlobalKey<FormState>();
            final newId = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('إضافة $label جديد'),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'الاسم'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final addedId = await onAdd(nameController.text.trim());
                        if (addedId != null) Navigator.pop(ctx, addedId);
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            );
            if (newId != null) {
              setState(() {
                if (label.contains('الوحدة')) _selectedUnitId = newId;
                if (label.contains('القياس')) _selectedSizeId = newId;
              });
            }
          },
          color: AddOrderForm.primaryColor,
        ),
      ],
    );
  }

  List<Widget> _buildProductFields() {
    return [
      BlocBuilder<StoreTypeCubit, StoreTypeState>(
        builder: (context, state) {
          if (state is StoreTypesLoading) return const Center(child: CircularProgressIndicator());
          if (state is StoreTypesLoaded) {
            final storeTypes = state.storeTypes.map((map) => StoreType.fromJson(map)).toList();
            return SearchableDropdownButton<StoreType>(
              label: "نوع المتجر",
              value: _selectedStoreTypeId,
              items: storeTypes,
              displayString: (st) => st.name,
              onChanged: (newId) {
                setState(() {
                  _selectedStoreTypeId = newId;
                  _selectedStoreId = null;
                  _selectedProductId = null;
                  _selectedUnitId = null;
                  _selectedSizeId = null;
                });
                if (newId != null) {
                  context.read<StoreCubit>().loadStores(storeTypeId: newId);
                  context.read<ProductCubit>().loadProducts(storeTypeId: newId);
                  context.read<UnitCubit>().loadUnits(storeTypeId: newId);
                  context.read<SizeCubit>().loadSizes(storeTypeId: newId);
                }
              },
              onAddItem: (name, {required parentId, required context}) async {
                try {
                  final api = ApiService();
                  final response = await api.createStoreType({'name': name});
                  if (response != null && response['id'] != null) {
                    await context.read<StoreTypeCubit>().loadStoreTypes();
                    return response['id'] as int;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                }
                return null;
              },
            );
          }
          return const SizedBox();
        },
      ),
      const SizedBox(height: 12),
      BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          if (_selectedStoreTypeId == null) return const SizedBox();
          if (state is StoresLoading) return const Center(child: CircularProgressIndicator());
          if (state is StoresLoaded) {
            return SearchableDropdownButton<Store>(
              label: "المتجر",
              value: _selectedStoreId,
              items: state.stores,
              displayString: (s) => s.name,
              onChanged: (storeId) => setState(() => _selectedStoreId = storeId),
              onAddItem: (name, {required parentId, required context}) async {
                if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                try {
                  final api = ApiService();
                  final response = await api.createStore({
                    'name': name,
                    'store_type_id': _selectedStoreTypeId,
                  });
                  if (response != null && response['id'] != null) {
                    await context.read<StoreCubit>().loadStores(storeTypeId: _selectedStoreTypeId);
                    return response['id'] as int;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                }
                return null;
              },
              requiresParent: true,
              parentId: _selectedStoreTypeId,
            );
          }
          return const SizedBox();
        },
      ),
      const SizedBox(height: 12),
      BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (_selectedStoreTypeId == null) return const SizedBox();
          if (state is ProductsLoading) return const Center(child: CircularProgressIndicator());
          if (state is ProductsLoaded) {
            return SearchableDropdownButton<Product>(
              label: "المنتج",
              value: _selectedProductId,
              items: state.products,
              displayString: (p) => p.name,
              onChanged: (productId) => setState(() => _selectedProductId = productId),
              onAddItem: (name, {required parentId, required context}) async {
                if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                try {
                  final api = ApiService();
                  final response = await api.createProduct({
                    'name': name,
                    'store_type_id': _selectedStoreTypeId,
                  });
                  if (response != null && response['id'] != null) {
                    await context.read<ProductCubit>().loadProducts(storeTypeId: _selectedStoreTypeId);
                    return response['id'] as int;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                }
                return null;
              },
              requiresParent: true,
              parentId: _selectedStoreTypeId,
            );
          }
          return const SizedBox();
        },
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _productQuantityController,
        decoration: _inputDecoration("الكمية *"),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
      ),
      const SizedBox(height: 12),
      BlocBuilder<UnitCubit, UnitState>(
        builder: (context, state) {
          if (_selectedStoreTypeId == null) return const SizedBox();
          if (state is UnitsLoading) return const Center(child: CircularProgressIndicator());
          if (state is UnitsLoaded) {
            if (state.units.isEmpty) {
              return _buildEmptyAddButton(
                label: "الوحدة",
                emptyMessage: "لا توجد وحدات متاحة لهذا النوع",
                onAdd: (name) async {
                  if (_selectedStoreTypeId == null) return null;
                  try {
                    final api = ApiService();
                    final response = await api.createUnit({
                      'name': name,
                      'store_type_id': _selectedStoreTypeId,
                    });
                    if (response != null && response['id'] != null) {
                      await context.read<UnitCubit>().loadUnits(storeTypeId: _selectedStoreTypeId);
                      return response['id'] as int;
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة الوحدة: $e'), backgroundColor: Colors.red));
                  }
                  return null;
                },
              );
            }
            return SearchableDropdownButton<Unit>(
              label: "الوحدة (اختياري)",
              value: _selectedUnitId,
              items: state.units,
              displayString: (u) => u.name,
              onChanged: (unitId) => setState(() => _selectedUnitId = unitId),
              onAddItem: (name, {required parentId, required context}) async {
                if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                try {
                  final api = ApiService();
                  final response = await api.createUnit({
                    'name': name,
                    'store_type_id': _selectedStoreTypeId,
                  });
                  if (response != null && response['id'] != null) {
                    await context.read<UnitCubit>().loadUnits(storeTypeId: _selectedStoreTypeId);
                    return response['id'] as int;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة الوحدة: $e'), backgroundColor: Colors.red));
                }
                return null;
              },
              requiresParent: true,
              parentId: _selectedStoreTypeId,
            );
          }
          return const SizedBox();
        },
      ),
      const SizedBox(height: 12),
      BlocBuilder<SizeCubit, SizeState>(
        builder: (context, state) {
          if (_selectedStoreTypeId == null) return const SizedBox();
          if (state is SizesLoading) return const Center(child: CircularProgressIndicator());
          if (state is SizesLoaded) {
            if (state.sizes.isEmpty) {
              return _buildEmptyAddButton(
                label: "القياس",
                emptyMessage: "لا توجد قياسات متاحة لهذا النوع",
                onAdd: (name) async {
                  if (_selectedStoreTypeId == null) return null;
                  try {
                    final api = ApiService();
                    final response = await api.createSize({
                      'name': name,
                      'store_type_id': _selectedStoreTypeId,
                    });
                    if (response != null && response['id'] != null) {
                      await context.read<SizeCubit>().loadSizes(storeTypeId: _selectedStoreTypeId);
                      return response['id'] as int;
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة القياس: $e'), backgroundColor: Colors.red));
                  }
                  return null;
                },
              );
            }
            return SearchableDropdownButton<Size>(
              label: "القياس (اختياري)",
              value: _selectedSizeId,
              items: state.sizes,
              displayString: (s) => s.name,
              onChanged: (sizeId) => setState(() => _selectedSizeId = sizeId),
              onAddItem: (name, {required parentId, required context}) async {
                if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                try {
                  final api = ApiService();
                  final response = await api.createSize({
                    'name': name,
                    'store_type_id': _selectedStoreTypeId,
                  });
                  if (response != null && response['id'] != null) {
                    await context.read<SizeCubit>().loadSizes(storeTypeId: _selectedStoreTypeId);
                    return response['id'] as int;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة القياس: $e'), backgroundColor: Colors.red));
                }
                return null;
              },
              requiresParent: true,
              parentId: _selectedStoreTypeId,
            );
          }
          return const SizedBox();
        },
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _productDescriptionController,
        decoration: _inputDecoration("وصف"),
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildDeliveryFields() => [
    TextField(controller: _pickupAddressController, decoration: _inputDecoration("عنوان الاستلام *")),
    const SizedBox(height: 12),
    TextField(controller: _pickupPhoneController, decoration: _inputDecoration("هاتف الاستلام"), keyboardType: TextInputType.phone),
    const SizedBox(height: 12),
    TextField(controller: _deliveryAddressItemController, decoration: _inputDecoration("عنوان التسليم *")),
    const SizedBox(height: 12),
    TextField(controller: _deliveryPhoneController, decoration: _inputDecoration("هاتف التسليم"), keyboardType: TextInputType.phone),
    const SizedBox(height: 12),
    TextField(controller: _deliveryDescriptionController, decoration: _inputDecoration("وصف"), maxLines: 2),
  ];

  List<Widget> _buildInvoiceFields() => [
    TextField(controller: _invoiceTypeController, decoration: _inputDecoration("نوع الفاتورة")),
    const SizedBox(height: 12),
    TextField(controller: _companyNameController, decoration: _inputDecoration("اسم الشركة *")),
    const SizedBox(height: 12),
    TextField(
      controller: _estimatedTotalController,
      decoration: _inputDecoration("المبلغ الإجمالي"),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(_decimalRegExp)],
    ),
    const SizedBox(height: 12),
    TextField(controller: _dueDateController, decoration: _inputDecoration("تاريخ الاستحقاق (YYYY-MM-DD)")),
    const SizedBox(height: 12),
    TextField(controller: _invoiceNotesController, decoration: _inputDecoration("ملاحظات"), maxLines: 2),
  ];

  void _addOrderItemFromFields() {
    if (_currentItemType == _OrderItemType.product) {
      if (_selectedStoreTypeId == null) return _showError("اختر نوع المتجر");
      if (_selectedStoreId == null) return _showError("اختر المتجر");
      if (_selectedProductId == null) return _showError("اختر المنتج");
      if (_productQuantityController.text.isEmpty) return _showError("أدخل الكمية");
    } else if (_currentItemType == _OrderItemType.delivery) {
      if (_pickupAddressController.text.isEmpty || _deliveryAddressItemController.text.isEmpty) return _showError("أدخل عنواني الاستلام والتسليم");
    } else if (_currentItemType == _OrderItemType.invoice) {
      if (_companyNameController.text.isEmpty) return _showError("أدخل اسم الشركة");
    }

    String? storeName, productName, unitName, sizeName;
    if (_currentItemType == _OrderItemType.product) {
      final storeState = context.read<StoreCubit>().state;
      if (storeState is StoresLoaded) {
        final store = storeState.stores.firstWhereOrNull((s) => s.id == _selectedStoreId);
        storeName = store?.name;
      }
      final productState = context.read<ProductCubit>().state;
      if (productState is ProductsLoaded) {
        final product = productState.products.firstWhereOrNull((p) => p.id == _selectedProductId);
        productName = product?.name;
      }
      if (_selectedUnitId != null) {
        final unitState = context.read<UnitCubit>().state;
        if (unitState is UnitsLoaded) {
          final unit = unitState.units.firstWhereOrNull((u) => u.id == _selectedUnitId);
          unitName = unit?.name;
        }
      }
      if (_selectedSizeId != null) {
        final sizeState = context.read<SizeCubit>().state;
        if (sizeState is SizesLoaded) {
          final size = sizeState.sizes.firstWhereOrNull((sz) => sz.id == _selectedSizeId);
          sizeName = size?.name;
        }
      }
    }

    OrderItem newItem;
    switch (_currentItemType) {
      case _OrderItemType.product:
        newItem = OrderItem(
          itemType: 'product',
          storeId: _selectedStoreId,
          storeName: storeName,
          productId: _selectedProductId,
          productName: productName,
          quantity: double.tryParse(_productQuantityController.text) ?? 1.0,
          unitId: _selectedUnitId,
          unitName: unitName,
          sizeId: _selectedSizeId,
          sizeName: sizeName,
          description: _productDescriptionController.text.isEmpty ? null : _productDescriptionController.text,
        );
        break;
      case _OrderItemType.delivery:
        newItem = OrderItem(
          itemType: 'delivery',
          pickupAddress: _pickupAddressController.text,
          pickupPhone: _pickupPhoneController.text.isEmpty ? null : _pickupPhoneController.text,
          deliveryAddress: _deliveryAddressItemController.text,
          deliveryPhone: _deliveryPhoneController.text.isEmpty ? null : _deliveryPhoneController.text,
          description: _deliveryDescriptionController.text.isEmpty ? null : _deliveryDescriptionController.text,
        );
        break;
      case _OrderItemType.invoice:
        newItem = OrderItem(
          itemType: 'invoice',
          invoiceType: _invoiceTypeController.text.isEmpty ? null : _invoiceTypeController.text,
          companyName: _companyNameController.text,
          estimatedTotal: double.tryParse(_estimatedTotalController.text),
          dueDate: _dueDateController.text.isNotEmpty ? DateTime.tryParse(_dueDateController.text) : null,
          notes: _invoiceNotesController.text.isEmpty ? null : _invoiceNotesController.text,
        );
        break;
    }

    setState(() => _orderItems.add(newItem));
    _clearTempFields();
    _showSuccess("تمت إضافة العنصر");
  }

  void _clearTempFields() {
    setState(() {
      _selectedStoreTypeId = null;
      _selectedStoreId = null;
      _selectedProductId = null;
      _selectedUnitId = null;
      _selectedSizeId = null;
      _productQuantityController.text = '1';
      _productDescriptionController.clear();
      _pickupAddressController.clear();
      _pickupPhoneController.clear();
      _deliveryAddressItemController.clear();
      _deliveryPhoneController.clear();
      _deliveryDescriptionController.clear();
      _invoiceTypeController.clear();
      _companyNameController.clear();
      _estimatedTotalController.clear();
      _dueDateController.clear();
      _invoiceNotesController.clear();
    });
  }

  Future<void> _submitOrder() async {
    String? missingField;

    if (_isEditingExistingCustomer) {
      if (_customerName.trim().isEmpty) missingField = "اسم العميل";
      else if (!_selectedPhones.any((selected) => selected)) missingField = "رقم هاتف واحد على الأقل";
      else if (_customerAddresses.isEmpty && (_selectedAddress == null || _selectedAddress!.addressText.isEmpty)) missingField = "عنوان العميل";
      else if (_customerAddresses.isNotEmpty && _selectedAddress == null) missingField = "عنوان العميل (اختر من القائمة)";
    } else {
      if (_newCustomerNameController.text.trim().isEmpty) missingField = "اسم العميل";
      else if (_primaryPhoneForNewCustomer.text.trim().isEmpty) missingField = "رقم الهاتف الأساسي";
      else if (_newAddressController.text.trim().isEmpty) missingField = "عنوان العميل";
    }

    if (missingField == null && _selectedDriverId == null) missingField = "السائق (يجب اختيار سائق متاح)";
    if (missingField == null && (_deliveryFeeController.text.isEmpty || double.tryParse(_deliveryFeeController.text) == null)) missingField = "أجرة التوصيل (قيمة رقمية)";
    if (missingField == null && _orderItems.isEmpty) missingField = "عنصر طلب واحد على الأقل (أضف منتجاً أو توصيلاً أو فاتورة)";

    if (missingField == null) {
      if (_paymentStatus == PaymentStatus.credit) {
        if (_orderTotalController.text.isEmpty || double.tryParse(_orderTotalController.text) == null) missingField = "إجمالي الطلب (لحالة الدَّين)";
      } else if (_paymentStatus == PaymentStatus.partial) {
        if (_paidAmountController.text.isEmpty || double.tryParse(_paidAmountController.text) == null) missingField = "المبلغ المدفوع";
        if (_orderTotalController.text.isEmpty || double.tryParse(_orderTotalController.text) == null) missingField = "قيمة الطلب";
      }
    }

    if (missingField != null) {
      _showError("الرجاء إدخال: $missingField");
      return;
    }

    if (_currentUserId == null) {
      await _loadCurrentUserId();
      if (_currentUserId == null) {
        _showError("الرجاء الانتظار قليلاً، لم يتم تحميل بيانات المستخدم بعد.");
        return;
      }
    }

    List<String> finalPhones = [];
    int? customerAddressId;

    if (_isEditingExistingCustomer) {
      for (int i = 0; i < _customerPhones.length; i++) {
        if (_selectedPhones[i]) finalPhones.add(_customerPhones[i]);
      }
      if (_customerAddresses.length > 1) {
        customerAddressId = _selectedAddress!.id;
      } else if (_customerAddresses.length == 1) {
        customerAddressId = _customerAddresses.first.id;
      } else {
        customerAddressId = null;
      }
    } else {
      finalPhones = [_primaryPhoneForNewCustomer.text.trim()];
    }

    setState(() => _isSubmitting = true);

    try {
      int? finalCustomerId = _isEditingExistingCustomer ? _originalCustomerId : null;

      if (!_isEditingExistingCustomer) {
        final primaryPhone = _primaryPhoneForNewCustomer.text.trim();
        final additionalPhones = _additionalPhoneControllers
            .map((c) => c.text.trim())
            .where((p) => p.isNotEmpty)
            .map((p) => CustomerPhone(phone: p))
            .toList();

        final newCustomer = Customer(
          id: 0,
          name: _newCustomerNameController.text.trim(),
          primaryPhone: primaryPhone,
          phones: additionalPhones,
          addresses: [
            Address(
              label: 'رئيسي',
              addressText: _newAddressController.text.trim(),
            )
          ],
          notes: _customerNotesController.text.trim().isEmpty ? null : _customerNotesController.text.trim(),
          balance: 0,
          isActive: true,
        );

        final created = await context.read<CustomerCubit>().addCustomer(newCustomer, password: '123456');
        if (created == null || created.id == 0) {
          throw Exception('لم يتم إرجاع بيانات العميل بعد الإضافة');
        }
        finalCustomerId = created.id;
        if (created.addresses.isNotEmpty && created.addresses.first.id != null) {
          customerAddressId = created.addresses.first.id;
        }
      } else if (_isEditing && _originalCustomerId != null) {
        final updatedCustomer = Customer(
          id: _originalCustomerId!,
          name: _customerName,
          primaryPhone: null,
          phones: [],
          addresses: [],
          notes: _customerNotesController.text.trim().isEmpty ? null : _customerNotesController.text.trim(),
          balance: 0,
          isActive: true,
        );
        await context.read<CustomerCubit>().updateCustomer(_originalCustomerId!, updatedCustomer);
        finalCustomerId = _originalCustomerId;
        if (_selectedAddress != null && _selectedAddress!.id != null) {
          customerAddressId = _selectedAddress!.id;
        }
      } else {
        finalCustomerId = _originalCustomerId;
      }

      for (int i = 0; i < _orderItems.length; i++) {
        _orderItems[i].sortOrder = i + 1;
      }

      double paid = 0.0;
      double remaining = 0.0;

      switch (_paymentStatus) {
        case PaymentStatus.cash:
          paid = 0;
          remaining = 0;
          break;
        case PaymentStatus.credit:
          final total = double.tryParse(_orderTotalController.text.trim());
          if (total == null) {
            _showError("إجمالي الطلب غير صحيح");
            return;
          }
          paid = 0;
          remaining = total;
          break;
        case PaymentStatus.partial:
          final total = double.tryParse(_orderTotalController.text.trim());
          final paidVal = double.tryParse(_paidAmountController.text.trim());
          if (total == null || paidVal == null) {
            _showError("قيم الطلب أو المدفوع غير صحيحة");
            return;
          }
          remaining = total;
          paid = paidVal;
          break;
      }

      List<double>? deliveryLocation;
      if (_selectedAddress?.latitude != null && _selectedAddress?.longitude != null) {
        deliveryLocation = [_selectedAddress!.longitude!, _selectedAddress!.latitude!];
      }

      OrderStatus newStatus;
      if (_isEditing) {
        if (_editingOrder!.status == OrderStatus.pending &&
            _selectedDriverId != _editingOrder!.driverId) {
          newStatus = OrderStatus.assigned;
        } else {
          newStatus = _editingOrder!.status;
        }
      } else {
        newStatus = OrderStatus.pending;
      }

      final order = Order(
        id: _isEditing ? _editingOrder!.id : 0,
        orderNumber: _isEditing ? _editingOrder!.orderNumber : Order.generateOrderNumber(),
        customerId: finalCustomerId!,
        officeUserId: _currentUserId,
        driverId: _selectedDriverId!,
        status: newStatus,
        deliveryFee: _deliveryFee,
        paymentStatus: _paymentStatus,
        paidAmount: paid,
        remainingAmount: remaining,
        deliveryLocation: deliveryLocation,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: _isEditing ? _editingOrder!.createdAt : DateTime.now(),
        items: _orderItems,
        customerAddressId: customerAddressId,
        orderPhones: finalPhones.join(','),
      );

      if (_isEditing) {
        final updatedOrder = await context.read<OrderCubit>().updateOrder(order);
        if (newStatus == OrderStatus.assigned) {
          await context.read<OrderCubit>().updateOrderStatus(order.id, 'assigned');
        }
        _showSuccess("تم تحديث الطلب بنجاح");
        Navigator.pop(context, updatedOrder);
      } else {
        await context.read<OrderCubit>().submitOrder(order);
        _showSuccess("تم إرسال الطلب بنجاح");
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is ApiException) {
        errorMsg = e.message;
      }
      if (errorMsg.contains('422')) {
        errorMsg = 'بيانات غير صالحة: تأكد من جميع الحقول المطلوبة (السائق، أجرة التوصيل، العناصر).';
      } else if (errorMsg.contains('401') || errorMsg.contains('403')) {
        errorMsg = 'غير مصرح: يرجى تسجيل الخروج والدخول مرة أخرى.';
      }
      _showError("فشل ${_isEditing ? 'تحديث' : 'إرسال'} الطلب: $errorMsg");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AddOrderForm.primaryColor),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AddOrderForm.primaryColor.withOpacity(0.5))),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AddOrderForm.primaryColor, width: 2)),
  );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  Widget _sectionContainer({required Widget child}) => Container(
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
    child: child,
  );
}

// ======================= Edit Dialogs (بدون تغيير) =======================
class _EditProductDialog extends StatefulWidget {
  final OrderItem item;
  const _EditProductDialog({required this.item});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  int? _selectedStoreTypeId;
  int? _selectedStoreId;
  int? _selectedProductId;
  int? _selectedUnitId;
  int? _selectedSizeId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _estimatedPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.item.storeId;
    _selectedProductId = widget.item.productId;
    _selectedUnitId = widget.item.unitId;
    _selectedSizeId = widget.item.sizeId;
    _quantityController.text = widget.item.quantity.toString();
    _estimatedPriceController.text = widget.item.estimatedPrice?.toString() ?? '';
    _descriptionController.text = widget.item.description ?? '';

    _loadStoreTypeForCurrentItem();
  }

  Future<void> _loadStoreTypeForCurrentItem() async {
    if (_selectedStoreId != null) {
      final storeTypeId = await _getStoreTypeIdForStore(_selectedStoreId!);
      if (storeTypeId != null) {
        setState(() {
          _selectedStoreTypeId = storeTypeId;
        });
        await _loadDataAfterStoreTypeSelected(storeTypeId);
      }
    }
  }

  Future<int?> _getStoreTypeIdForStore(int storeId) async {
    final state = context.read<StoreCubit>().state;
    if (state is StoresLoaded) {
      final store = state.stores.firstWhereOrNull((s) => s.id == storeId);
      if (store != null) return store.storeTypeId;
    }
    await context.read<StoreCubit>().loadStores();
    final newState = context.read<StoreCubit>().state;
    if (newState is StoresLoaded) {
      final store = newState.stores.firstWhereOrNull((s) => s.id == storeId);
      if (store != null) return store.storeTypeId;
    }
    return null;
  }

  Future<void> _loadDataAfterStoreTypeSelected(int storeTypeId) async {
    await Future.wait([
      context.read<StoreCubit>().loadStores(storeTypeId: storeTypeId),
      context.read<ProductCubit>().loadProducts(storeTypeId: storeTypeId),
      context.read<UnitCubit>().loadUnits(storeTypeId: storeTypeId),
      context.read<SizeCubit>().loadSizes(storeTypeId: storeTypeId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المنتج'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<StoreTypeCubit, StoreTypeState>(
              builder: (context, state) {
                if (state is StoreTypesLoading) return const Center(child: CircularProgressIndicator());
                if (state is StoreTypesLoaded) {
                  final storeTypes = state.storeTypes.map((map) => StoreType.fromJson(map)).toList();
                  return SearchableDropdownButton<StoreType>(
                    label: "نوع المتجر",
                    value: _selectedStoreTypeId,
                    items: storeTypes,
                    displayString: (st) => st.name,
                    onChanged: (newId) async {
                      setState(() {
                        _selectedStoreTypeId = newId;
                        _selectedStoreId = null;
                        _selectedProductId = null;
                        _selectedUnitId = null;
                        _selectedSizeId = null;
                      });
                      if (newId != null) await _loadDataAfterStoreTypeSelected(newId);
                    },
                    onAddItem: (name, {required parentId, required context}) async {
                      try {
                        final api = ApiService();
                        final response = await api.createStoreType({'name': name});
                        if (response != null && response['id'] != null) {
                          await context.read<StoreTypeCubit>().loadStoreTypes();
                          return response['id'] as int;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                      }
                      return null;
                    },
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<StoreCubit, StoreState>(
              builder: (context, state) {
                if (_selectedStoreTypeId == null) return const SizedBox();
                if (state is StoresLoading) return const Center(child: CircularProgressIndicator());
                if (state is StoresLoaded) {
                  return SearchableDropdownButton<Store>(
                    label: "المتجر",
                    value: _selectedStoreId,
                    items: state.stores,
                    displayString: (s) => s.name,
                    onChanged: (storeId) => setState(() => _selectedStoreId = storeId),
                    onAddItem: (name, {required parentId, required context}) async {
                      if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                      try {
                        final api = ApiService();
                        final response = await api.createStore({
                          'name': name,
                          'store_type_id': _selectedStoreTypeId,
                        });
                        if (response != null && response['id'] != null) {
                          await context.read<StoreCubit>().loadStores(storeTypeId: _selectedStoreTypeId);
                          return response['id'] as int;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                      }
                      return null;
                    },
                    requiresParent: true,
                    parentId: _selectedStoreTypeId,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (_selectedStoreTypeId == null) return const SizedBox();
                if (state is ProductsLoading) return const Center(child: CircularProgressIndicator());
                if (state is ProductsLoaded) {
                  return SearchableDropdownButton<Product>(
                    label: "المنتج",
                    value: _selectedProductId,
                    items: state.products,
                    displayString: (p) => p.name,
                    onChanged: (productId) => setState(() => _selectedProductId = productId),
                    onAddItem: (name, {required parentId, required context}) async {
                      if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                      try {
                        final api = ApiService();
                        final response = await api.createProduct({
                          'name': name,
                          'store_type_id': _selectedStoreTypeId,
                        });
                        if (response != null && response['id'] != null) {
                          await context.read<ProductCubit>().loadProducts(storeTypeId: _selectedStoreTypeId);
                          return response['id'] as int;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: Colors.red));
                      }
                      return null;
                    },
                    requiresParent: true,
                    parentId: _selectedStoreTypeId,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'الكمية *'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            BlocBuilder<UnitCubit, UnitState>(
              builder: (context, state) {
                if (_selectedStoreTypeId == null) return const SizedBox();
                if (state is UnitsLoading) return const Center(child: CircularProgressIndicator());
                if (state is UnitsLoaded) {
                  if (state.units.isEmpty) return const Text('لا توجد وحدات متاحة', style: TextStyle(color: Colors.grey));
                  return SearchableDropdownButton<Unit>(
                    label: "الوحدة (اختياري)",
                    value: _selectedUnitId,
                    items: state.units,
                    displayString: (u) => u.name,
                    onChanged: (unitId) => setState(() => _selectedUnitId = unitId),
                    onAddItem: (name, {required parentId, required context}) async {
                      if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                      try {
                        final api = ApiService();
                        final response = await api.createUnit({
                          'name': name,
                          'store_type_id': _selectedStoreTypeId,
                        });
                        if (response != null && response['id'] != null) {
                          await context.read<UnitCubit>().loadUnits(storeTypeId: _selectedStoreTypeId);
                          return response['id'] as int;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة الوحدة: $e'), backgroundColor: Colors.red));
                      }
                      return null;
                    },
                    requiresParent: true,
                    parentId: _selectedStoreTypeId,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<SizeCubit, SizeState>(
              builder: (context, state) {
                if (_selectedStoreTypeId == null) return const SizedBox();
                if (state is SizesLoading) return const Center(child: CircularProgressIndicator());
                if (state is SizesLoaded) {
                  if (state.sizes.isEmpty) return const Text('لا توجد قياسات متاحة', style: TextStyle(color: Colors.grey));
                  return SearchableDropdownButton<Size>(
                    label: "القياس (اختياري)",
                    value: _selectedSizeId,
                    items: state.sizes,
                    displayString: (s) => s.name,
                    onChanged: (sizeId) => setState(() => _selectedSizeId = sizeId),
                    onAddItem: (name, {required parentId, required context}) async {
                      if (_selectedStoreTypeId == null) throw Exception('اختر نوع المتجر أولاً');
                      try {
                        final api = ApiService();
                        final response = await api.createSize({
                          'name': name,
                          'store_type_id': _selectedStoreTypeId,
                        });
                        if (response != null && response['id'] != null) {
                          await context.read<SizeCubit>().loadSizes(storeTypeId: _selectedStoreTypeId);
                          return response['id'] as int;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إضافة القياس: $e'), backgroundColor: Colors.red));
                      }
                      return null;
                    },
                    requiresParent: true,
                    parentId: _selectedStoreTypeId,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _estimatedPriceController,
              decoration: const InputDecoration(labelText: 'السعر التقديري'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            if (_selectedStoreId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المتجر'), backgroundColor: Colors.red));
              return;
            }
            if (_selectedProductId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المنتج'), backgroundColor: Colors.red));
              return;
            }
            if (_quantityController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال الكمية'), backgroundColor: Colors.red));
              return;
            }

            String? storeName, productName, unitName, sizeName;
            final storeState = context.read<StoreCubit>().state;
            if (storeState is StoresLoaded) {
              final store = storeState.stores.firstWhereOrNull((s) => s.id == _selectedStoreId);
              storeName = store?.name;
            }
            final productState = context.read<ProductCubit>().state;
            if (productState is ProductsLoaded) {
              final product = productState.products.firstWhereOrNull((p) => p.id == _selectedProductId);
              productName = product?.name;
            }
            if (_selectedUnitId != null) {
              final unitState = context.read<UnitCubit>().state;
              if (unitState is UnitsLoaded) {
                final unit = unitState.units.firstWhereOrNull((u) => u.id == _selectedUnitId);
                unitName = unit?.name;
              }
            }
            if (_selectedSizeId != null) {
              final sizeState = context.read<SizeCubit>().state;
              if (sizeState is SizesLoaded) {
                final size = sizeState.sizes.firstWhereOrNull((sz) => sz.id == _selectedSizeId);
                sizeName = size?.name;
              }
            }

            final updated = OrderItem(
              id: widget.item.id,
              orderId: widget.item.orderId,
              itemType: 'product',
              storeId: _selectedStoreId,
              storeName: storeName,
              productId: _selectedProductId,
              productName: productName,
              quantity: double.tryParse(_quantityController.text) ?? 1.0,
              unitId: _selectedUnitId,
              unitName: unitName,
              sizeId: _selectedSizeId,
              sizeName: sizeName,
              estimatedPrice: double.tryParse(_estimatedPriceController.text),
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
              isAvailable: widget.item.isAvailable,
              sortOrder: widget.item.sortOrder,
            );
            Navigator.pop(context, updated);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _EditDeliveryDialog extends StatefulWidget {
  final OrderItem item;
  const _EditDeliveryDialog({required this.item});

  @override
  State<_EditDeliveryDialog> createState() => _EditDeliveryDialogState();
}

class _EditDeliveryDialogState extends State<_EditDeliveryDialog> {
  late TextEditingController _pickupAddressController;
  late TextEditingController _pickupPhoneController;
  late TextEditingController _deliveryAddressController;
  late TextEditingController _deliveryPhoneController;
  late TextEditingController _estimatedFeeController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _pickupAddressController = TextEditingController(text: widget.item.pickupAddress ?? '');
    _pickupPhoneController = TextEditingController(text: widget.item.pickupPhone ?? '');
    _deliveryAddressController = TextEditingController(text: widget.item.deliveryAddress ?? '');
    _deliveryPhoneController = TextEditingController(text: widget.item.deliveryPhone ?? '');
    _estimatedFeeController = TextEditingController(text: widget.item.estimatedFee?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل خدمة التوصيل'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(controller: _pickupAddressController, decoration: const InputDecoration(labelText: 'عنوان الاستلام')),
            const SizedBox(height: 8),
            TextFormField(controller: _pickupPhoneController, decoration: const InputDecoration(labelText: 'هاتف الاستلام'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextFormField(controller: _deliveryAddressController, decoration: const InputDecoration(labelText: 'عنوان التسليم')),
            const SizedBox(height: 8),
            TextFormField(controller: _deliveryPhoneController, decoration: const InputDecoration(labelText: 'هاتف التسليم'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextFormField(controller: _estimatedFeeController, decoration: const InputDecoration(labelText: 'الأجرة التقديرية'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'الوصف')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            final updated = OrderItem(
              id: widget.item.id,
              orderId: widget.item.orderId,
              itemType: 'delivery',
              pickupAddress: _pickupAddressController.text,
              pickupPhone: _pickupPhoneController.text.isEmpty ? null : _pickupPhoneController.text,
              deliveryAddress: _deliveryAddressController.text,
              deliveryPhone: _deliveryPhoneController.text.isEmpty ? null : _deliveryPhoneController.text,
              estimatedFee: double.tryParse(_estimatedFeeController.text),
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
              sortOrder: widget.item.sortOrder,
            );
            Navigator.pop(context, updated);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _EditInvoiceDialog extends StatefulWidget {
  final OrderItem item;
  const _EditInvoiceDialog({required this.item});

  @override
  State<_EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<_EditInvoiceDialog> {
  late TextEditingController _invoiceTypeController;
  late TextEditingController _companyNameController;
  late TextEditingController _estimatedTotalController;
  late TextEditingController _dueDateController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _invoiceTypeController = TextEditingController(text: widget.item.invoiceType ?? '');
    _companyNameController = TextEditingController(text: widget.item.companyName ?? '');
    _estimatedTotalController = TextEditingController(text: widget.item.estimatedTotal?.toString() ?? '');
    _dueDateController = TextEditingController(text: widget.item.dueDate?.toIso8601String().split('T').first ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الفاتورة'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(controller: _invoiceTypeController, decoration: const InputDecoration(labelText: 'نوع الفاتورة')),
            const SizedBox(height: 8),
            TextFormField(controller: _companyNameController, decoration: const InputDecoration(labelText: 'اسم الشركة')),
            const SizedBox(height: 8),
            TextFormField(controller: _estimatedTotalController, decoration: const InputDecoration(labelText: 'المبلغ الإجمالي'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextFormField(controller: _dueDateController, decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق (YYYY-MM-DD)')),
            const SizedBox(height: 8),
            TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            final updated = OrderItem(
              id: widget.item.id,
              orderId: widget.item.orderId,
              itemType: 'invoice',
              invoiceType: _invoiceTypeController.text.isEmpty ? null : _invoiceTypeController.text,
              companyName: _companyNameController.text,
              estimatedTotal: double.tryParse(_estimatedTotalController.text),
              dueDate: _dueDateController.text.isNotEmpty ? DateTime.tryParse(_dueDateController.text) : null,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
              sortOrder: widget.item.sortOrder,
            );
            Navigator.pop(context, updated);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}