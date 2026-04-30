// lib/screens/orders_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/order_cubit.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة الطلبات',
            style: TextStyle(
              color: primaryColor,
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
              color: primaryColor.withOpacity(0.3),
            ),
          ),
          iconTheme: const IconThemeData(color: primaryColor),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, primaryColor.withOpacity(0.15)],
            ),
          ),
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
                          return _OrderCard(order: order);
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
        ),
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
          // شريط البحث
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
          // خيارات الفلتر والترتيب
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

// بطاقة عرض الطلب (لون أبيض خالص بدون شفافية)
class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  static const Color primaryColor = Color(0xFF54d4dd);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'timeout':
        return Colors.grey;
      case 'on_the_way':
        return Colors.purple;
      case 'items_purchased':
        return Colors.teal;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade900;
      default:
        return Colors.grey;
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
      color: Colors.white, // لون أبيض خالص
      child: InkWell(
        onTap: () {
          _showOrderDetailsDialog(context, order);
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

  void _showOrderDetailsDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      'تفاصيل الطلب ${_getDisplayOrderNumber()}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 24),
                  _detailRow('رقم الطلب:', _getDisplayOrderNumber()),
                  _detailRow('العميل:', order.customerName ?? 'غير محدد'),
                  _detailRow('حالة الطلب:', _getStatusName(order.status.name)),
                  _detailRow('طريقة الدفع:', _getPaymentStatusName(order.paymentStatus.name)),
                  _detailRow('رسوم التوصيل:', '${order.deliveryFee} ريال'),
                  _detailRow('المبلغ المدفوع:', '${order.paidAmount} ريال'),
                  _detailRow('المبلغ المتبقي:', '${order.remainingAmount} ريال'),
                  _detailRow('تاريخ الإنشاء:', _formatDate(order.createdAt)),
                  if (order.acceptedAt != null)
                    _detailRow('تاريخ القبول:', _formatDate(order.acceptedAt!)),
                  if (order.deliveredAt != null)
                    _detailRow('تاريخ التسليم:', _formatDate(order.deliveredAt!)),
                  if (order.driverName != null && order.driverName!.isNotEmpty)
                    _detailRow('السائق:', order.driverName!),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _detailRow('ملاحظات:', order.notes!),
                  if (order.items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'الأصناف:',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...order.items.map((item) => _itemTile(item)),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('إغلاق', style: TextStyle(color: primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusName(String status) {
    switch (status) {
      case 'cash': return 'كاش';
      case 'credit': return 'آجل';
      case 'partial': return 'جزئي';
      default: return status;
    }
  }

  Widget _itemTile(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.productName != null && item.productName!.isNotEmpty)
            Text('المنتج: ${item.productName}', style: const TextStyle(color: Colors.black87)),
          if (item.quantity != null)
            Text('الكمية: ${item.quantity}', style: const TextStyle(color: Colors.black54)),
          if (item.estimatedPrice != null)
            Text('السعر التقديري: ${item.estimatedPrice} ريال', style: const TextStyle(color: Colors.black54)),
          if (item.actualPrice != null)
            Text('السعر الفعلي: ${item.actualPrice} ريال', style: const TextStyle(color: Colors.green)),
          if (item.itemType == 'delivery')
            const Text('نوع الخدمة: توصيل', style: TextStyle(color: Colors.orange)),
          if (item.itemType == 'invoice')
            const Text('نوع الخدمة: فاتورة', style: TextStyle(color: Colors.purple)),
        ],
      ),
    );
  }
}