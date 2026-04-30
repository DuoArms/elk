// lib/screens/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/order_cubit.dart';
import '../models/order.dart';
import 'add_order_form.dart';
import 'change_item_store_screen.dart';
import 'login_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final int? highlightedItemId;
  final int? highlightedStoreTypeId;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.highlightedItemId,
    this.highlightedStoreTypeId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color primaryColor = Color(0xFF54d4dd);
  late Order _order;
  bool _isLoading = true; // لتحديث البيانات من الخادم

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _reloadOrderFromServer(); // جلب أحدث البيانات فوراً
  }

  // جلب الطلب من الخادم لضمان تحديث البيانات (الحالة، السائق، العميل)
  Future<void> _reloadOrderFromServer() async {
    try {
      await context.read<OrderCubit>().loadOrderById(_order.id);
      final state = context.read<OrderCubit>().state;
      if (state is OrderLoaded && mounted) {
        setState(() {
          _order = state.order; // تحديث الكائن بأحدث البيانات
          _isLoading = false;
        });
      } else if (state is OrderError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الطلب: ${state.message}'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الطلب: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // تحديث يدوي (مثلاً بعد تغيير المتجر)
  Future<void> _manualRefresh() async {
    setState(() => _isLoading = true);
    await _reloadOrderFromServer();
  }

  // ========== الحسابات المالية ==========
  double _getTotalInvoice(Order order) => order.remainingAmount;
  double _getRemainingAmount(Order order) => (order.remainingAmount + order.deliveryFee) - order.paidAmount;

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

  void _confirmDeleteOrder(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الطلب رقم ${order.orderNumber}؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري حذف الطلب...')));
              await context.read<OrderCubit>().deleteOrder(order.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditOrder(BuildContext context) async {
    final updatedOrder = await Navigator.push<Order>(
      context,
      MaterialPageRoute(builder: (context) => AddOrderForm(initialOrder: _order)),
    );
    if (updatedOrder != null) {
      setState(() {
        _order = updatedOrder;
      });
      if (context.mounted) context.read<OrderCubit>().loadOrders();
      _manualRefresh(); // تحديث من الخادم أيضاً
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final totalInvoice = _getTotalInvoice(order);
    final remainingAmount = _getRemainingAmount(order);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طلب ${order.orderNumber}', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 22)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: primaryColor.withOpacity(0.3)),
          ),
          iconTheme: const IconThemeData(color: primaryColor),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: primaryColor),
              onPressed: () {
                _manualRefresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تحديث البيانات...')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, primaryColor.withOpacity(0.15)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('حالة الطلب:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor(order.status)),
                          ),
                          child: Text(_getStatusText(order.status), style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.grey),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('طريقة الدفع:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(order.paymentStatus.name == 'cash' ? 'نقداً' : order.paymentStatus.name == 'credit' ? 'دين' : 'جزئي', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('المبلغ المدفوع:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${order.paidAmount.toStringAsFixed(2)} ل.س', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('إجمالي الفاتورة:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${totalInvoice.toStringAsFixed(2)} ل.س', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('المبلغ المتبقي:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${remainingAmount.toStringAsFixed(2)} ل.س', style: TextStyle(color: remainingAmount > 0 ? Colors.red : Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.person, color: primaryColor), const SizedBox(width: 8), Text('معلومات العميل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(height: 16, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('الاسم: ${order.customerName ?? 'غير معروف'}', style: const TextStyle(color: Colors.black87)),
                    if (order.orderPhones != null && order.orderPhones!.isNotEmpty) Text('الهواتف: ${order.orderPhones}', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.customerAddress != null)
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.location_on, color: primaryColor), const SizedBox(width: 8), Text('عنوان العميل', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))]),
                      const Divider(height: 16, color: Colors.grey),
                      const SizedBox(height: 8),
                      if (order.customerAddress!['label'] != null && order.customerAddress!['label'].toString().isNotEmpty)
                        Text('التسمية: ${order.customerAddress!['label']}', style: const TextStyle(color: Colors.black87)),
                      if (order.customerAddress!['address'] != null && order.customerAddress!['address'].toString().isNotEmpty)
                        Text('العنوان: ${order.customerAddress!['address']}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.local_taxi, color: primaryColor), const SizedBox(width: 8), Text('معلومات السائق', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(height: 16, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('الاسم: ${order.driverName ?? 'غير معين'}', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('أجرة التوصيل: ${order.deliveryFee.toStringAsFixed(2)} ل.س', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.shopping_cart, color: primaryColor), const SizedBox(width: 8), Text('عناصر الطلب', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(height: 16, color: Colors.grey),
                    const SizedBox(height: 8),
                    if (order.items.isEmpty)
                      const Text('لا توجد عناصر', style: TextStyle(color: Colors.black87))
                    else
                      Column(
                        children: order.items.map((item) {
                          String title;
                          String subtitle;
                          Widget? extraDetails;

                          if (item.itemType == 'product') {
                            title = item.productName ?? (item.productId != null ? 'منتج #${item.productId}' : 'منتج');
                            subtitle = '${item.quantity} ${item.unitName ?? ''} - ${item.estimatedPrice?.toStringAsFixed(2) ?? '?'} ل.س';
                            List<String> details = [];
                            if (item.storeName != null && item.storeName!.isNotEmpty) details.add('المتجر: ${item.storeName}');
                            if (item.unitName != null && item.unitName!.isNotEmpty) details.add('الوحدة: ${item.unitName}');
                            if (item.sizeId != null) details.add('القياس: #${item.sizeId}');
                            if (item.description != null && item.description!.isNotEmpty) details.add('الملاحظات: ${item.description}');
                            if (details.isNotEmpty) {
                              extraDetails = Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(details.join(' • '), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              );
                            }

                            if (item.id != null && item.id == widget.highlightedItemId) {
                              extraDetails = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (extraDetails != null) extraDetails,
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      if (widget.highlightedStoreTypeId == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('لا يمكن تحديد نوع المتجر'), backgroundColor: Colors.red),
                                        );
                                        return;
                                      }
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChangeItemStoreScreen(
                                            orderId: order.id,
                                            itemId: item.id!,
                                            storeTypeId: widget.highlightedStoreTypeId!,
                                            productName: item.productName ?? 'المنتج',
                                            currentStoreName: item.storeName ?? 'المتجر',
                                          ),
                                        ),
                                      );
                                      if (result == true) _manualRefresh();
                                    },
                                    icon: const Icon(Icons.swap_horiz, size: 16),
                                    label: const Text('تغيير المتجر'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ],
                              );
                            }
                          } else if (item.itemType == 'delivery') {
                            title = 'توصيل';
                            String descriptionPart = (item.description != null && item.description!.isNotEmpty) ? ' (${item.description})' : '';
                            subtitle = '${item.pickupAddress} -> ${item.deliveryAddress}$descriptionPart';
                          } else {
                            title = 'فاتورة: ${item.companyName}';
                            subtitle = 'المبلغ: ${item.estimatedTotal?.toStringAsFixed(2) ?? '?'}';
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(title, style: const TextStyle(color: Colors.black87)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                if (extraDetails != null) extraDetails,
                              ],
                            ),
                            leading: Icon(
                              item.itemType == 'product' ? Icons.inventory : item.itemType == 'delivery' ? Icons.delivery_dining : Icons.receipt,
                              color: primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.notes != null && order.notes!.isNotEmpty)
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملاحظات:', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(order.notes!, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToEditOrder(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل الطلب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteOrder(context, order),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('حذف الطلب نهائياً'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
}