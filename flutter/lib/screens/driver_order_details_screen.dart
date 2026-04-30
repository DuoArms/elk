// lib/screens/driver_order_details_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/order_cubit.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import 'login_screen.dart';

const Color primaryTeal = Color(0xFF54d4dd);
const Color textDark = Color(0xFF212121);
const Color textMedium = Color(0xFF424242);
const Color textLight = Color(0xFF757575);
const Color accentGreen = Color(0xFF2E7D32);
const Color accentRed = Color(0xFFC62828);
const Color accentOrange = Color(0xFFE65100);
const Color accentBlue = Color(0xFF1565C0);

class DriverOrderDetailsScreen extends StatefulWidget {
  final Order order;
  const DriverOrderDetailsScreen({super.key, required this.order});

  @override
  State<DriverOrderDetailsScreen> createState() => _DriverOrderDetailsScreenState();
}

class _DriverOrderDetailsScreenState extends State<DriverOrderDetailsScreen> {
  late OrderStatus _currentStatus;
  bool _isAccepting = false;
  bool _isRejecting = false;
  bool _isStatusUpdating = false;
  bool _isSavingStoreTotals = false;
  bool _isUpdatingItem = false;

  final Map<int, bool> _itemAvailable = {};
  final Map<int, TextEditingController> _storeTotalControllers = {};
  final Map<int, bool> _storeTotalSaved = {};

  double _statusSliderValue = 0;
  final List<OrderStatus> _statusSteps = [
    OrderStatus.on_the_way,
    OrderStatus.items_purchased,
    OrderStatus.delivered
  ];

  static const Map<int, String> _sizeNames = {1: 'صغير', 2: 'وسط', 3: 'كبير'};

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _updateSliderFromStatus();

    for (var item in widget.order.items) {
      final id = item.id ?? _generateItemHash(item);
      _itemAvailable[id] = item.isAvailable;
    }

    final storeIds = <int>{};
    for (var item in widget.order.items) {
      if (item.storeId != null && !storeIds.contains(item.storeId)) {
        storeIds.add(item.storeId!);
        _storeTotalControllers[item.storeId!] = TextEditingController();
        _storeTotalSaved[item.storeId!] = false;
      }
    }
  }

  int _generateItemHash(OrderItem item) {
    return '${item.productId}${item.description}${item.quantity}'.hashCode;
  }

  void _updateSliderFromStatus() {
    switch (_currentStatus) {
      case OrderStatus.on_the_way:
        _statusSliderValue = 0;
        break;
      case OrderStatus.items_purchased:
        _statusSliderValue = 1;
        break;
      case OrderStatus.delivered:
        _statusSliderValue = 2;
        break;
      default:
        _statusSliderValue = 0;
    }
  }

  @override
  void dispose() {
    for (var c in _storeTotalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isOrderActive =>
      _currentStatus == OrderStatus.on_the_way ||
          _currentStatus == OrderStatus.items_purchased ||
          _currentStatus == OrderStatus.delivered;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _acceptOrder() async {
    setState(() => _isAccepting = true);
    try {
      await context.read<OrderCubit>().acceptOrder(widget.order.id);
      await context.read<OrderCubit>().updateOrderStatus(widget.order.id, 'on_the_way');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب والانتقال إلى "في الطريق"'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _currentStatus = OrderStatus.on_the_way;
        _updateSliderFromStatus();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل قبول الطلب: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _rejectOrder() async {
    setState(() => _isRejecting = true);
    try {
      await context.read<OrderCubit>().rejectOrder(widget.order.id);
      await context.read<OrderCubit>().loadDriverOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض الطلب وإبلاغ المكتب'), backgroundColor: Colors.orange),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفض الطلب: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  Future<void> _onSliderChanged(double value) async {
    if (!_isOrderActive) return;

    final newIndex = value.round();
    final newStatus = _statusSteps[newIndex];
    if (newStatus == _currentStatus) return;

    setState(() => _isStatusUpdating = true);
    try {
      await context.read<OrderCubit>().updateOrderStatus(widget.order.id, newStatus.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _currentStatus = newStatus;
        _statusSliderValue = value;
      });
      if (newStatus == OrderStatus.delivered) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث الحالة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isStatusUpdating = false);
    }
  }

  Future<void> _updateItemAvailability(OrderItem item, bool available) async {
    if (!_isOrderActive) return;

    setState(() => _isUpdatingItem = true);
    try {
      await context.read<OrderCubit>().updateOrderItem(
        widget.order.id,
        item.id!,
        isAvailable: available,
      );
      if (!mounted) return;
      final id = item.id ?? _generateItemHash(item);
      setState(() => _itemAvailable[id] = available);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(available ? 'تم تحديث الحالة إلى متوفر' : 'تم إبلاغ المكتب بعدم التوفر'),
          backgroundColor: available ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحديث: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingItem = false);
    }
  }

  Future<void> _saveSingleStoreTotal(int storeId) async {
    if (!_isOrderActive) return;

    final controller = _storeTotalControllers[storeId];
    if (controller == null) return;
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال قيمة المشتريات'), backgroundColor: Colors.red),
      );
      return;
    }
    final amount = double.tryParse(text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قيمة المشتريات يجب أن تكون رقماً صحيحاً'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingStoreTotals = true);
    try {
      await context.read<OrderCubit>().addStoreTotal(
        orderId: widget.order.id,
        storeId: storeId,
        totalAmount: amount,
      );
      if (!mounted) return;
      setState(() => _storeTotalSaved[storeId] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إجمالي المتجر بنجاح'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingStoreTotals = false);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.assigned: return Colors.blue;
      case OrderStatus.accepted: return Colors.green;
      case OrderStatus.rejected: return Colors.red;
      case OrderStatus.timeout: return Colors.grey;
      case OrderStatus.on_the_way: return Colors.purple;
      case OrderStatus.items_purchased: return Colors.teal;
      case OrderStatus.delivered: return Colors.green.shade700;
      case OrderStatus.cancelled: return Colors.red.shade900;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'قيد الانتظار';
      case OrderStatus.assigned: return 'معين';
      case OrderStatus.accepted: return 'مقبول';
      case OrderStatus.rejected: return 'مرفوض';
      case OrderStatus.timeout: return 'انتهى الوقت';
      case OrderStatus.on_the_way: return 'في الطريق';
      case OrderStatus.items_purchased: return 'تم الشراء';
      case OrderStatus.delivered: return 'تم التوصيل';
      case OrderStatus.cancelled: return 'ملغي';
    }
  }

  String _getSizeName(int? sizeId) {
    if (sizeId == null) return '';
    return _sizeNames[sizeId] ?? '';
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canAccept = _currentStatus == OrderStatus.assigned;

    final Map<int, String> storeNames = {};
    for (var item in widget.order.items) {
      if (item.storeId != null) {
        storeNames[item.storeId!] = item.storeName?.isNotEmpty == true
            ? item.storeName!
            : 'متجر ${item.storeId}';
      }
    }

    // 🟢 استخراج بيانات العميل بشكل صحيح
    final customerName = widget.order.customerName ?? 'غير معروف';
    final customerPhones = widget.order.orderPhones ?? 'غير محددة';

    String customerAddress = 'غير محدد';
    String? addressLabel;

    if (widget.order.customerAddress != null) {
      final dynamic raw = widget.order.customerAddress;
      Map<String, dynamic>? addressMap;

      if (raw is Map) {
        addressMap = raw.cast<String, dynamic>();
      } else {
        // محاولة تحويل الكائن إلى خريطة إذا كان لديه toJson
        try {
          final json = (raw as dynamic).toJson();
          if (json is Map) {
            addressMap = Map<String, dynamic>.from(json);
          }
        } catch (_) {}
      }

      if (addressMap != null) {
        customerAddress = addressMap['address'] ??
            addressMap['address_text'] ??
            'غير محدد';
        addressLabel = addressMap['label'];
      }
    }

    // ---- فصل عناصر المنتج عن غيرها ----
    final productItems = widget.order.items.where((i) => i.itemType == 'product').toList();
    final otherItems = widget.order.items.where((i) => i.itemType != 'product').toList();

    // تجميع المنتجات حسب storeId
    final Map<int?, List<OrderItem>> groupedProducts = {};
    for (var item in productItems) {
      final storeId = item.storeId;
      if (!groupedProducts.containsKey(storeId)) {
        groupedProducts[storeId] = [];
      }
      groupedProducts[storeId]!.add(item);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'تفاصيل الطلب #${widget.order.orderNumber}',
            style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 22),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(color: primaryTeal.withOpacity(0.4), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.only(top: kToolbarHeight + 20, left: 16, right: 16, bottom: 30),
            children: [
              // بطاقة الحالة
              _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالة الطلب الحالية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentStatus).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _getStatusColor(_currentStatus), width: 1.2),
                        ),
                        child: Text(_getStatusText(_currentStatus),
                            style: TextStyle(color: _getStatusColor(_currentStatus), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      if (canAccept) ...[
                        Row(children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isAccepting ? null : _acceptOrder,
                              icon: _isAccepting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle),
                              label: Text(_isAccepting ? 'جاري القبول...' : 'قبول الطلب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isRejecting ? null : _rejectOrder,
                              icon: _isRejecting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.close, color: Colors.red),
                              label: Text(_isRejecting ? 'جاري الرفض...' : 'رفض الطلب'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        ]),
                      ],
                      if (_isOrderActive) ...[
                        const SizedBox(height: 20),
                        Text('تقدم الطلب:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTeal)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Slider(
                              value: _statusSliderValue,
                              min: 0,
                              max: 2,
                              divisions: 2,
                              label: _getStatusText(_statusSteps[_statusSliderValue.round()]),
                              onChanged: _isStatusUpdating ? null : _onSliderChanged,
                              activeColor: primaryTeal,
                              inactiveColor: primaryTeal.withOpacity(0.2),
                            ),
                          ),
                          if (_isStatusUpdating)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal)),
                            ),
                        ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _statusSteps.map((s) => Text(_getStatusText(s), style: TextStyle(color: textLight))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // معلومات العميل + الأجرة
              _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(Icons.person, color: primaryTeal)),
                        const SizedBox(width: 12),
                        Text('معلومات العميل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                      ]),
                      const Divider(height: 24, color: Colors.grey),
                      Text('الاسم: $customerName', style: TextStyle(color: textDark, fontSize: 15)),
                      const SizedBox(height: 10),
                      Text('الهواتف: $customerPhones', style: TextStyle(color: textDark, fontSize: 15)),
                      const SizedBox(height: 10),
                      if (addressLabel != null && addressLabel!.isNotEmpty)
                        Text('تسمية العنوان: $addressLabel', style: TextStyle(color: textDark, fontSize: 15)),
                      Text('العنوان: $customerAddress', style: TextStyle(color: textDark, fontSize: 15)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentGreen.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.monetization_on, color: accentGreen, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('أجرة التوصيل (يجب تحصيلها من الزبون)',
                                    style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${widget.order.deliveryFee.toStringAsFixed(2)} ل.س',
                                    style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold, fontSize: 20)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              // باقي البطاقات...
              const SizedBox(height: 20),
              if (widget.order.paymentStatus != PaymentStatus.cash &&
                  (widget.order.remainingAmount > 0 || widget.order.paidAmount > 0))
                _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.account_balance_wallet, color: accentOrange),
                          const SizedBox(width: 8),
                          Text('تفاصيل الدفع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                        ]),
                        const Divider(height: 24, color: Colors.grey),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('قيمة الطلب:', style: TextStyle(color: textDark)),
                          Text('${widget.order.remainingAmount.toStringAsFixed(2)} ل.س',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('المبلغ المدفوع:', style: TextStyle(color: textDark)),
                          Text('${widget.order.paidAmount.toStringAsFixed(2)} ل.س',
                              style: TextStyle(color: Colors.green.shade800)),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('المبلغ المتبقي:', style: TextStyle(color: textDark)),
                          Text(
                            '${(widget.order.remainingAmount - widget.order.paidAmount).toStringAsFixed(2)} ل.س',
                            style: TextStyle(
                                color: (widget.order.remainingAmount - widget.order.paidAmount) > 0
                                    ? Colors.red
                                    : Colors.green),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // ---- بطاقة عناصر الطلب مع تجميع المنتجات حسب المتجر ----
              _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(Icons.shopping_cart, color: primaryTeal)),
                        const SizedBox(width: 12),
                        Text('عناصر الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                      ]),
                      const Divider(height: 24, color: Colors.grey),
                      if (widget.order.items.isEmpty)
                        Padding(padding: const EdgeInsets.all(16), child: Text('لا توجد عناصر في هذا الطلب', style: TextStyle(color: textLight)))
                      else ...[
                        // عرض المنتجات المجمعة
                        for (var entry in groupedProducts.entries)
                          _buildStoreGroupCard(entry.key, entry.value),
                        // عرض العناصر غير المنتج (توصيل، فاتورة)
                        ...otherItems.map((item) => _buildItemCard(item)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (storeNames.isNotEmpty)
                _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.store, color: primaryTeal)),
                          const SizedBox(width: 12),
                          Text('تسجيل المشتريات من المتاجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
                        ]),
                        const Divider(height: 24, color: Colors.grey),
                        if (!_isOrderActive)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('سيتم تفعيل تسجيل المشتريات بعد قبول الطلب.',
                                style: TextStyle(color: Colors.grey.shade600)),
                          )
                        else
                          ...storeNames.entries.map((entry) {
                            final storeId = entry.key;
                            final storeName = entry.value;
                            final isSaved = _storeTotalSaved[storeId] ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(flex: 2, child: Text(storeName,
                                      style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w500))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _storeTotalControllers[storeId],
                                      enabled: !isSaved && !_isSavingStoreTotals && _isOrderActive,
                                      style: TextStyle(color: isSaved ? textLight : textDark),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'المبلغ (ل.س)',
                                        labelStyle: TextStyle(color: primaryTeal),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryTeal.withOpacity(0.5))),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryTeal, width: 2)),
                                        disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isSaved)
                                    IconButton(
                                      icon: _isSavingStoreTotals
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                          : Icon(Icons.save, color: primaryTeal),
                                      onPressed: (_isSavingStoreTotals || !_isOrderActive)
                                          ? null
                                          : () => _saveSingleStoreTotal(storeId),
                                    )
                                  else
                                    Icon(Icons.check_circle, color: accentGreen, size: 28),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 8),
                        Text('يمكنك تسجيل المشتريات في أي وقت بعد قبول الطلب. بعد الحفظ لا يمكن تعديل القيمة.',
                            style: TextStyle(fontSize: 12, color: textLight), textAlign: TextAlign.center),
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

  // بطاقة مجموعة متجر تحتوي على منتجاته
  Widget _buildStoreGroupCard(int? storeId, List<OrderItem> items) {
    final storeName = items.first.storeName ?? (storeId != null ? 'متجر $storeId' : 'متجر غير معروف');
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: primaryTeal.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.store, size: 18, color: primaryTeal),
                const SizedBox(width: 8),
                Text(
                  storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTeal),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) => _buildProductCard(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    switch (item.itemType) {
      case 'product': return _buildProductCard(item);
      case 'delivery': return _buildDeliveryCard(item);
      case 'invoice': return _buildInvoiceCard(item);
      default: return _buildProductCard(item);
    }
  }

  Widget _buildProductCard(OrderItem item) {
    final id = item.id ?? _generateItemHash(item);
    final isAvailable = _itemAvailable[id] ?? item.isAvailable;
    final productName = (item.productName?.isNotEmpty == true) ? item.productName! : 'منتج بدون اسم';
    final storeName = (item.storeName?.isNotEmpty == true) ? item.storeName! : '';
    final quantity = item.quantity;
    final unitName = (item.unitName?.isNotEmpty == true) ? item.unitName! : '';
    final sizeName = _getSizeName(item.sizeId);
    final estimatedPrice = item.estimatedPrice;
    final actualPrice = item.actualPrice;
    final description = item.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName, style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                    if (storeName.isNotEmpty) Text('المتجر: $storeName', style: TextStyle(color: accentBlue, fontSize: 12)),
                  ],
                ),
              ),
              if (_isOrderActive && isAvailable)

                ElevatedButton.icon(
                  onPressed: _isUpdatingItem ? null : () => _updateItemAvailability(item, false),
                  icon: const Icon(Icons.cancel, size: 10),
                  label: const Text('غير موجود'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 4, children: [
            Text('الكمية: $quantity $unitName', style: TextStyle(color: textLight, fontSize: 13)),
            if (sizeName.isNotEmpty) Text('الحجم: $sizeName', style: TextStyle(color: textLight, fontSize: 13)),
          ]),
          if (description != null && description.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text('وصف: $description', style: TextStyle(color: textMedium, fontSize: 13))),
          if (estimatedPrice != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('السعر التقديري: ${estimatedPrice.toStringAsFixed(2)} ل.س', style: TextStyle(color: textMedium, fontSize: 13))),
          if (actualPrice != null)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('السعر الفعلي: ${actualPrice.toStringAsFixed(2)} ل.س', style: TextStyle(color: accentGreen, fontWeight: FontWeight.w500, fontSize: 13))),
          if (item.unavailableReason != null && item.unavailableReason!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('سبب عدم التوفر: ${item.unavailableReason}', style: TextStyle(color: accentRed, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.local_shipping, color: accentOrange), const SizedBox(width: 8), Text('توصيل غرض', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(),
          if (item.description != null && item.description!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('وصف الغرض: ${item.description}', style: TextStyle(color: textDark))),
          if (item.pickupAddress != null)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('مكان الاستلام: ${item.pickupAddress}', style: TextStyle(color: textDark))),
          if (item.pickupContactName != null || item.pickupPhone != null)
            Text('جهة الاتصال (استلام): ${item.pickupContactName ?? ''} - ${item.pickupPhone ?? ''}', style: TextStyle(color: textMedium)),
          const SizedBox(height: 8),
          if (item.deliveryAddress != null)
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('مكان التسليم: ${item.deliveryAddress}', style: TextStyle(color: textDark))),
          if (item.deliveryContactName != null || item.deliveryPhone != null)
            Text('جهة الاتصال (تسليم): ${item.deliveryContactName ?? ''} - ${item.deliveryPhone ?? ''}', style: TextStyle(color: textMedium)),
          const SizedBox(height: 8),
          if (item.estimatedFee != null)
            Text('الأجرة التقديرية: ${item.estimatedFee!.toStringAsFixed(2)} ل.س', style: TextStyle(color: textMedium)),
          if (item.actualFee != null)
            Text('الأجرة الفعلية: ${item.actualFee!.toStringAsFixed(2)} ل.س', style: TextStyle(color: accentGreen, fontWeight: FontWeight.w500)),
          if (item.notes != null && item.notes!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('ملاحظات: ${item.notes}', style: TextStyle(color: textLight))),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.receipt, color: accentBlue), const SizedBox(width: 8), Text('دفع فاتورة', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(),
          if (item.companyName != null && item.companyName!.isNotEmpty)
            Text('الشركة: ${item.companyName}', style: TextStyle(color: textDark)),
          if (item.invoiceType != null && item.invoiceType!.isNotEmpty)
            Text('نوع الفاتورة: ${item.invoiceType}', style: TextStyle(color: textMedium)),
          if (item.estimatedTotal != null)
            Text('المبلغ المقدر: ${item.estimatedTotal!.toStringAsFixed(2)} ل.س', style: TextStyle(color: textMedium)),
          if (item.actualInvoiceAmount != null)
            Text('المبلغ الفعلي: ${item.actualInvoiceAmount!.toStringAsFixed(2)} ل.س', style: TextStyle(color: accentGreen, fontWeight: FontWeight.w500)),
          if (item.dueDate != null)
            Text('تاريخ الاستحقاق: ${item.dueDate!.toLocal().toString().split(' ')[0]}', style: TextStyle(color: textLight)),
          if (item.description != null && item.description!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('وصف: ${item.description}', style: TextStyle(color: textLight))),
          if (item.notes != null && item.notes!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('ملاحظات: ${item.notes}', style: TextStyle(color: textLight))),
        ],
      ),
    );
  }
}