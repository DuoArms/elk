// lib/screens/driver_dashboard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/driver_cubit.dart';
import '../cubits/order_cubit.dart';
import '../cubits/NotificationCubit.dart';
import '../cubits/notification_state.dart';
import '../models/order.dart';
import 'driver_order_details_screen.dart';
import 'Notifications_Screen.dart';
import 'login_screen.dart';

const Color primaryTeal = Color(0xFF54d4dd);

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _selectedStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<OrderCubit>().loadDriverOrders();
      await context.read<DriverCubit>().loadDriverProfile();
      if (mounted) {
        context.read<NotificationCubit>().loadUnreadCount();
      }
    } catch (e) {
      setState(() => _errorMessage = 'فشل في تحميل البيانات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() => _loadData();

  void _filterByStatus(String? status) {
    setState(() => _selectedStatus = status);
    context.read<OrderCubit>().filterByStatus(status);
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade100],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight + 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildAvailabilityToggle(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatusFilter(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : BlocBuilder<OrderCubit, OrderState>(
                  builder: (context, state) {
                    if (state is OrdersLoading) {
                      return const Center(child: CircularProgressIndicator(color: primaryTeal));
                    } else if (state is OrdersLoaded) {
                      final orders = state.filteredOrders;
                      if (orders.isEmpty) {
                        return _buildEmptyState();
                      }
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        color: primaryTeal,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _DriverOrderCard(order: order);
                          },
                        ),
                      );
                    } else if (state is OrderError) {
                      return _buildErrorWidget(message: state.message);
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'طلباتي',
        style: TextStyle(
          color: primaryTeal,
          fontWeight: FontWeight.w900,
          fontSize: 28,
          letterSpacing: 0.5,
        ),
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
                bottom: BorderSide(
                  color: primaryTeal.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is NotificationsLoaded) {
              unreadCount = state.unreadCount;
            }
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: primaryTeal),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ).then((_) {
                      context.read<NotificationCubit>().loadUnreadCount();
                    });
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: primaryTeal),
          onPressed: _refresh,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _logout,
          tooltip: 'تسجيل الخروج',
        ),
      ],
    );
  }

  Widget _buildAvailabilityToggle() {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, state) {
        bool isAvailable = true;
        if (state is DriverProfileLoaded) {
          isAvailable = state.driver.isAvailable;
        }
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable ? Colors.green : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (isAvailable ? Colors.green : Colors.red).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isAvailable ? 'متاح لتلقي الطلبات' : 'غير متاح حالياً',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) => context.read<DriverCubit>().toggleAvailability(),
                  activeColor: primaryTeal,
                  activeTrackColor: primaryTeal.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String?>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'تصفية حسب الحالة',
            labelStyle: TextStyle(color: primaryTeal, fontWeight: FontWeight.w500),
            border: InputBorder.none,
            icon: Icon(Icons.filter_list, color: primaryTeal),
          ),
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.grey[800], fontSize: 15),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('الكل')),
            ...OrderStatus.values.map((status) {
              return DropdownMenuItem<String?>(
                value: status.name,
                child: Text(_getStatusText(status)),
              );
            }),
          ],
          onChanged: _filterByStatus,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message ?? 'حدث خطأ غير متوقع',
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
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
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
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
      ),
    );
  }
}

class _DriverOrderCard extends StatelessWidget {
  final Order order;
  const _DriverOrderCard({required this.order});

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
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DriverOrderDetailsScreen(order: order)),
            ).then((_) => context.read<OrderCubit>().loadDriverOrders());
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _getStatusColor(order.status), width: 1.2),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, size: 18, color: primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'غير معروف',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${order.deliveryFee.toStringAsFixed(2)} ل.س',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${order.items.length} عناصر',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}