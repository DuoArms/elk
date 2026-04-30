import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/order_cubit.dart';
import '../models/order.dart';
import 'order_details_screen.dart';  // ✅ تمت إضافة هذا السطر

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _statusFilter;

  static const Color primaryColor = Color(0xFF54d4dd);

  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DropdownMenuItem<String?> _buildStatusItem(OrderStatus status) {
    final text = switch (status) {
      OrderStatus.pending => 'قيد الانتظار',
      OrderStatus.assigned => 'معين لسائق',
      OrderStatus.accepted => 'مقبول',
      OrderStatus.rejected => 'مرفوض',
      OrderStatus.timeout => 'انتهى الوقت',
      OrderStatus.on_the_way => 'في الطريق',
      OrderStatus.items_purchased => 'تم الشراء',
      OrderStatus.delivered => 'تم التوصيل',
      OrderStatus.cancelled => 'ملغي',
    };
    return DropdownMenuItem<String?>(
      value: status.name,
      child: Text(text),
    );
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
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: primaryColor),
              onPressed: () => context.read<OrderCubit>().loadOrders(),
            ),
          ],
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildFilterBar(),
              ),
              Expanded(
                child: BlocBuilder<OrderCubit, OrderState>(
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    } else if (state is OrdersLoaded) {
                      final orders = state.filteredOrders;
                      if (orders.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد طلبات',
                            style: TextStyle(color: Colors.grey[600], fontSize: 18),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          await context.read<OrderCubit>().loadOrders();
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _OrderCard(order: order);
                          },
                        ),
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

  Widget _buildFilterBar() {
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
      child: DropdownButtonFormField<String?>(
        value: _statusFilter,
        decoration: InputDecoration(
          labelText: 'تصفية حسب الحالة',
          labelStyle: TextStyle(color: primaryColor),
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
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: Icon(Icons.filter_list, color: primaryColor),
        ),
        dropdownColor: Colors.white,
        style: TextStyle(color: Colors.grey[800]),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('الكل')),
          ...OrderStatus.values.map(_buildStatusItem),
        ],
        onChanged: (value) {
          setState(() => _statusFilter = value);
          context.read<OrderCubit>().filterByStatus(value);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  static const Color primaryColor = Color(0xFF54d4dd);

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(order.status)),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    order.customerName ?? 'غير معروف',
                    style: TextStyle(color: Colors.grey[800], fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${order.deliveryFee.toStringAsFixed(2)} ل.س',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.payment, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    order.paymentStatus.name == 'cash' ? 'نقداً' : order.paymentStatus.name == 'credit' ? 'دين' : 'جزئي',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              if (order.driverName != null) ...[
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200]),
                Row(
                  children: [
                    Icon(Icons.local_taxi, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'السائق: ${order.driverName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}