import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/NotificationCubit.dart';
import '../cubits/notification_state.dart';
import '../cubits/order_cubit.dart'; // ✅ جديد
import '../models/NotificationModel.dart';
import '../models/order.dart';
import 'order_details_screen.dart';
import 'change_item_store_screen.dart';
import 'login_screen.dart';

const Color _primaryTeal = Color(0xFF54d4dd);

class OfficeNotificationsScreen extends StatelessWidget {
  const OfficeNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NotificationCubit()),
        BlocProvider(create: (context) => OrderCubit()), // ✅ لإتاحة جلب الطلب
      ],
      child: const _OfficeNotificationsContent(),
    );
  }
}

class _OfficeNotificationsContent extends StatefulWidget {
  const _OfficeNotificationsContent();

  @override
  State<_OfficeNotificationsContent> createState() =>
      _OfficeNotificationsContentState();
}

class _OfficeNotificationsContentState extends State<_OfficeNotificationsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterType;
  bool? _filterRead;
  bool _isLoading = false;

  List<String> get _availableTypes {
    final state = context.read<NotificationCubit>().state;
    if (state is NotificationsLoaded) {
      final types = state.notifications
          .map((n) => n.type)
          .whereType<String>()
          .toSet()
          .toList();
      types.sort();
      return types;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      await context.read<NotificationCubit>().loadNotifications();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
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

  List<NotificationModel> _filterNotifications(
      List<NotificationModel> notifications) {
    return notifications.where((n) {
      if (_searchQuery.isNotEmpty) {
        final title = n.title?.toLowerCase() ?? '';
        final body = n.body?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !body.contains(query)) return false;
      }
      if (_filterType != null && n.type != _filterType) return false;
      if (_filterRead != null && n.isRead != _filterRead) return false;
      return true;
    }).toList();
  }

  // ✅ دالة لجلب الطلب الحالي من الخادم والانتقال إلى التفاصيل
  Future<void> _navigateToOrderDetails(int orderId) async {
    // عرض مؤشر تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<OrderCubit>().loadOrderById(orderId);
      final state = context.read<OrderCubit>().state;
      Navigator.pop(context); // إغلاق المؤشر

      if (state is OrderLoaded) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: state.order),
          ),
        );
      } else if (state is OrderError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الطلب: ${state.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الطلب: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات',
              style: TextStyle(color: _primaryTeal, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _primaryTeal.withOpacity(0.3)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              onPressed: () async {
                await context.read<NotificationCubit>().markAllRead();
              },
              tooltip: 'تحديد الكل كمقروء',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadNotifications(),
              tooltip: 'تحديث',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is NotificationsLoaded) {
                    final filtered = _filterNotifications(state.notifications);
                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text('لا توجد إشعارات',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        await _loadNotifications();
                      },
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final notification = filtered[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
                    );
                  } else if (state is NotificationError) {
                    return Center(
                        child: Text('خطأ: ${state.message}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'بحث في العنوان أو المحتوى...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                    label: 'الكل',
                    selected: _filterRead == null,
                    onSelected: () => setState(() => _filterRead = null)),
                _buildFilterChip(
                    label: 'غير مقروء',
                    selected: _filterRead == false,
                    onSelected: () => setState(() => _filterRead = false)),
                _buildFilterChip(
                    label: 'مقروء',
                    selected: _filterRead == true,
                    onSelected: () => setState(() => _filterRead = true)),
                const SizedBox(width: 8),
                ..._availableTypes.map((type) {
                  return _buildFilterChip(
                    label: type,
                    selected: _filterType == type,
                    onSelected: () {
                      setState(() {
                        _filterType = (_filterType == type) ? null : type;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: _primaryTeal,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () async {
        // تحديث الحالة إلى مقروء (محلياً وفوراً) قبل فتح الشاشة
        if (!notification.isRead) {
          await context.read<NotificationCubit>().markAsRead(notification.id);
        }

        if (notification.type == 'product_unavailable' && notification.order != null) {
          final orderData = notification.order!;
          final productName = notification.product?['name'] ?? 'المنتج';
          final storeName = notification.store?['name'] ?? 'المتجر';
          final driverName = notification.driver?['user']?['full_name'] ?? 'غير معروف';
          int? itemId = notification.itemId;
          int? storeTypeId = notification.storeTypeId;

          // الحل الاحتياطي القوي
          if ((itemId == null || itemId == 0 || storeTypeId == null || storeTypeId == 0) &&
              orderData['items'] != null) {
            final items = orderData['items'] as List?;
            if (items != null) {
              for (var it in items) {
                if (it['is_available'] == false) {
                  itemId = it['id'];
                  if (it['store'] != null && it['store']['store_type_id'] != null) {
                    storeTypeId = it['store']['store_type_id'];
                  }
                  break;
                }
              }
            }
          }

          if (itemId != null && storeTypeId != null && itemId != 0 && storeTypeId != 0) {
            // ✅ نذهب مباشرة إلى شاشة تغيير المتجر
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeItemStoreScreen(
                  orderId: orderData['id'],
                  itemId: itemId!,
                  storeTypeId: storeTypeId!,
                  productName: productName,
                  currentStoreName: storeName,
                  driverName: driverName,
                ),
              ),
            );
          } else {
            // ✅ نجلب الطلب الحقيقي من الخادم لنضمن أحدث البيانات
            _navigateToOrderDetails(orderData['id']);
          }
        } else if (notification.orderId != null) {
          // ✅ نجلب الطلب الحقيقي من الخادم لضمان ظهور أحدث البيانات (السائق، العميل)
          _navigateToOrderDetails(notification.orderId!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: notification.isRead
                ? Colors.white
                : _primaryTeal.withOpacity(0.05),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getIconColor(notification.type),
              child: Icon(_getIcon(notification.type),
                  color: Colors.white, size: 22),
            ),
            title: Text(
              notification.title ?? 'إشعار',
              style: TextStyle(
                fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(notification.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'new_order':
      case 'order_assigned':
        return Icons.local_shipping;
      case 'driver_accepted':
        return Icons.check_circle;
      case 'driver_rejected':
        return Icons.cancel;
      case 'status_changed':
        return Icons.sync;
      case 'product_unavailable':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'new_order':
        return Colors.green;
      case 'driver_accepted':
        return Colors.teal;
      case 'driver_rejected':
        return Colors.red;
      case 'status_changed':
        return Colors.orange;
      case 'product_unavailable':
        return Colors.amber;
      default:
        return _primaryTeal;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays >= 1) {
      return 'قبل ${difference.inDays} يوم';
    } else if (difference.inHours >= 1) {
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inMinutes >= 1) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}