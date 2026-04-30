import '../models/NotificationModel.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationsLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationsLoaded(this.notifications, this.unreadCount);
}

class NotificationError extends NotificationState {
  final String message;
  NotificationError(this.message);
}