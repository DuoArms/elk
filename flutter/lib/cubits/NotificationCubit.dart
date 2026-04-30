import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/NotificationModel.dart';
import '../services/api_service.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final ApiService _api = ApiService();

  NotificationCubit() : super(NotificationInitial());

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    try {
      final response = await _api.get('notifications');
      List<dynamic> rawList = response is List ? response : response['data'] ?? [];
      List<NotificationModel> notifications = rawList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      int unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(notifications, unreadCount));
    } catch (e) {
      emit(NotificationError('فشل تحميل الإشعارات: $e'));
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('notifications/unread-count');
      int count = response['count'] ?? 0;
      if (state is NotificationsLoaded) {
        final current = state as NotificationsLoaded;
        emit(NotificationsLoaded(current.notifications, count));
      } else {
        emit(NotificationsLoaded([], count));
      }
    } catch (e) {
      emit(NotificationError('فشل تحميل عدد الإشعارات غير المقروءة: $e'));
    }
  }

  Future<void> markAsRead(int id) async {
    // 1. تحديث الحالة محلياً فوراً (للحصول على تجربة سريعة)
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final updatedNotifications = current.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(updatedNotifications, newUnreadCount));
    }

    // 2. إرسال الطلب إلى الخادم في الخلفية (لا ننتظر النتيجة لتجنب التأخير)
    try {
      await _api.post('notifications/$id/read', {});
    } catch (e) {
      // في حال فشل الطلب، يمكن استعادة الحالة السابقة (اختياري)
      // لكننا سنتجاهل الخطأ حتى لا يزعج المستخدم
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllRead() async {
    // تحديث محلي فوري
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      final updatedNotifications = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(NotificationsLoaded(updatedNotifications, 0));
    }

    // إرسال طلب الخادم في الخلفية
    try {
      await _api.post('notifications/mark-all-read', {});
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}