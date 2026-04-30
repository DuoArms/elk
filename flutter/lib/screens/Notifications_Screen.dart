// lib/screens/Notifications_Screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/NotificationCubit.dart';
import '../cubits/notification_state.dart';
import '../cubits/order_cubit.dart';
import '../models/order.dart';
import 'driver_order_details_screen.dart';
import 'login_screen.dart';

const Color primaryTeal = Color(0xFF54d4dd);

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NotificationCubit>().loadNotifications();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'الإشعارات',
            style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w900, fontSize: 24),
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
              icon: const Icon(Icons.done_all, color: primaryTeal),
              onPressed: () => context.read<NotificationCubit>().markAllRead(),
              tooltip: 'تحديد الكل كمقروء',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
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
          child: BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return const Center(child: CircularProgressIndicator(color: primaryTeal));
              }
              if (state is NotificationError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('خطأ: ${state.message}', style: TextStyle(color: Colors.red.shade700)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.read<NotificationCubit>().loadNotifications(),
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
              if (state is NotificationsLoaded) {
                if (state.notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('لا توجد إشعارات', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<NotificationCubit>().loadNotifications(),
                  color: primaryTeal,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: kToolbarHeight + 20, left: 16, right: 16, bottom: 30),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final n = state.notifications[index];
                      final orderNumber = n.order != null ? n.order!['order_number'] : null;
                      final driverName = n.driver != null && n.driver!['user'] != null
                          ? n.driver!['user']['full_name']
                          : (n.sender != null ? n.sender!['full_name'] : null);
                      final productName = n.product != null ? n.product!['name'] : null;
                      final storeName = n.store != null ? n.store!['name'] : null;

                      return Dismissible(
                        key: Key(n.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.done, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          context.read<NotificationCubit>().markAsRead(n.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديد الإشعار كمقروء'), backgroundColor: Colors.green),
                          );
                        },
                        child: _buildNotificationCard(context, n, orderNumber, driverName, productName, storeName),
                      );
                    },
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      dynamic n,
      dynamic orderNumber,
      String? driverName,
      String? productName,
      String? storeName,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: n.isRead ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: n.isRead ? Colors.grey.shade300 : primaryTeal.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (n.order != null) {
                    final order = Order.fromJson(n.order!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DriverOrderDetailsScreen(order: order)),
                    ).then((_) {
                      context.read<OrderCubit>().loadDriverOrders();
                    });
                  } else if (n.orderId != null) {
                    context.read<OrderCubit>().loadOrderById(n.orderId!).then((_) {
                      final state = context.read<OrderCubit>().state;
                      if (state is OrderLoaded) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DriverOrderDetailsScreen(order: state.order)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فشل تحميل الطلب'), backgroundColor: Colors.red),
                        );
                      }
                    });
                  }
                  if (!n.isRead) {
                    context.read<NotificationCubit>().markAsRead(n.id);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(n.type),
                          color: n.isRead ? Colors.grey : primaryTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title ?? 'إشعار',
                              style: TextStyle(
                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                                color: n.isRead ? Colors.grey.shade700 : textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.body ?? '',
                              style: TextStyle(
                                color: n.isRead ? Colors.grey.shade600 : Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (orderNumber != null)
                                  Chip(
                                    label: Text('#$orderNumber', style: const TextStyle(fontSize: 12)),
                                    backgroundColor: primaryTeal.withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (driverName != null)
                                  Chip(
                                    label: Text(driverName, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (productName != null)
                                  Chip(
                                    label: Text(productName, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (storeName != null)
                                  Chip(
                                    label: Text(storeName, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.purple.withOpacity(0.1),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(n.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        IconButton(
                          icon: const Icon(Icons.done, color: Colors.green),
                          onPressed: () => context.read<NotificationCubit>().markAsRead(n.id),
                          tooltip: 'تحديد كمقروء',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'product_unavailable':
        return Icons.remove_shopping_cart;
      case 'driver_rejected':
        return Icons.cancel;
      case 'driver_accepted':
        return Icons.check_circle;
      case 'status_changed':
        return Icons.update;
      case 'order_assigned':
      case 'new_order':
        return Icons.assignment;
      case 'item_store_changed':
        return Icons.store;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
}

const Color textDark = Color(0xFF212121);