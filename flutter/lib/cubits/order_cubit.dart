import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {}
class OrdersLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final Order order;
  OrderLoaded(this.order);
}

class OrdersLoaded extends OrderState {
  final List<Order> allOrders;
  final List<Order> filteredOrders;
  final String? filterStatus;
  final String sortBy;
  final String searchQuery;

  OrdersLoaded({
    required this.allOrders,
    this.filterStatus,
    this.sortBy = 'newest',
    this.searchQuery = '',
  }) : filteredOrders = _applyFilters(allOrders, filterStatus, searchQuery, sortBy);

  static List<Order> _applyFilters(
      List<Order> orders,
      String? status,
      String query,
      String sort,
      ) {
    List<Order> result = List.from(orders);
    if (status != null && status.isNotEmpty) {
      result = result.where((o) => o.status.name == status).toList();
    }
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      result = result.where((o) {
        if (o.orderNumber.toLowerCase().contains(lower)) return true;
        if (o.customerName?.toLowerCase().contains(lower) ?? false) return true;
        return false;
      }).toList();
    }
    if (sort == 'newest') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sort == 'oldest') {
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (sort == 'status') {
      result.sort((a, b) => a.status.name.compareTo(b.status.name));
    }
    return result;
  }

  OrdersLoaded copyWith({
    List<Order>? allOrders,
    String? filterStatus,
    String? sortBy,
    String? searchQuery,
  }) {
    return OrdersLoaded(
      allOrders: allOrders ?? this.allOrders,
      filterStatus: filterStatus ?? this.filterStatus,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrderSubmitting extends OrderState {}
class OrderSubmitted extends OrderState {
  final Order order;
  OrderSubmitted(this.order);
}
class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repo = OrderRepository();

  OrderCubit() : super(OrderInitial());

  Future<void> loadOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await _repo.fetchOrders();
      emit(OrdersLoaded(allOrders: orders));
    } catch (e) {
      emit(OrderError('فشل تحميل الطلبات: ${e.toString()}'));
    }
  }

  Future<void> loadOrderById(int orderId) async {
    emit(OrdersLoading());
    try {
      final order = await _repo.fetchOrderById(orderId);
      emit(OrderLoaded(order));
    } catch (e) {
      emit(OrderError('فشل تحميل الطلب: ${e.toString()}'));
    }
  }

  Future<void> loadDriverOrders() async {
    emit(OrdersLoading());
    try {
      final orders = await _repo.fetchDriverOrders();
      emit(OrdersLoaded(allOrders: orders));
    } catch (e) {
      emit(OrderError('فشل تحميل طلبات السائق: $e'));
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _repo.updateOrderStatus(orderId, newStatus);
      await _refreshAfterAction();
    } catch (e) {
      emit(OrderError('فشل تحديث حالة الطلب: $e'));
    }
  }

  Future<void> acceptOrder(int orderId) async {
    try {
      await _repo.acceptOrder(orderId);
      await _refreshAfterAction();
    } catch (e) {
      emit(OrderError('فشل قبول الطلب: $e'));
    }
  }

  Future<void> rejectOrder(int orderId) async {
    try {
      await _repo.rejectOrder(orderId);
      await _refreshAfterAction();
    } catch (e) {
      emit(OrderError('فشل رفض الطلب: $e'));
    }
  }

  Future<void> updateOrderItem(
      int orderId,
      int itemId, {
        bool? isAvailable,
        double? actualPrice,
        String? unavailableReason,
      }) async {
    try {
      await _repo.updateOrderItem(
        orderId,
        itemId,
        isAvailable: isAvailable,
        actualPrice: actualPrice,
        unavailableReason: unavailableReason,
      );
      await _refreshAfterAction();
    } catch (e) {
      throw Exception('فشل تحديث العنصر: $e');
    }
  }

  Future<void> addStoreTotal({
    required int orderId,
    required int storeId,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      await _repo.addStoreTotal(
        orderId: orderId,
        storeId: storeId,
        totalAmount: totalAmount,
        notes: notes,
      );
    } catch (e) {
      throw Exception('فشل تسجيل إجمالي المتجر: $e');
    }
  }

  Future<void> submitOrder(Order order) async {
    emit(OrderSubmitting());
    try {
      final payload = order.toJson();
      if (payload['items'] == null || payload['items'].isEmpty) {
        throw Exception('لا يمكن إرسال طلب بدون عناصر');
      }
      final newOrder = await _repo.createOrder(order);
      emit(OrderSubmitted(newOrder));
      await loadOrders();
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<Order> updateOrder(Order order) async {
    emit(OrderSubmitting());
    try {
      final updatedOrder = await _repo.updateOrder(order);
      emit(OrderSubmitted(updatedOrder));
      await loadOrders();
      return updatedOrder;
    } catch (e) {
      emit(OrderError('فشل تحديث الطلب: ${e.toString()}'));
      rethrow;
    }
  }

  Future<void> deleteOrder(int orderId) async {
    emit(OrdersLoading());
    try {
      await _repo.deleteOrder(orderId);
      await loadOrders();
    } catch (e) {
      emit(OrderError('فشل حذف الطلب: ${e.toString()}'));
    }
  }

  void filterByStatus(String? status) {
    final current = state;
    if (current is OrdersLoaded) {
      emit(current.copyWith(filterStatus: status));
    }
  }

  void sortOrders(String sortBy) {
    final current = state;
    if (current is OrdersLoaded) {
      emit(current.copyWith(sortBy: sortBy));
    }
  }

  void searchOrders(String query) {
    final current = state;
    if (current is OrdersLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  void reset() {
    emit(OrderInitial());
  }

  // دالة تغيير متجر عنصر
  Future<void> changeItemStore(int orderId, int itemId, int newStoreId) async {
    try {
      await _repo.changeItemStore(orderId, itemId, newStoreId);
    } catch (e) {
      emit(OrderError('فشل تغيير المتجر: $e'));
    }
  }

  Future<void> _refreshAfterAction() async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      await _refreshOrdersKeepingFilter(currentState);
    } else {
      await loadDriverOrders();
    }
  }

  Future<void> _refreshOrdersKeepingFilter(OrdersLoaded currentState) async {
    try {
      final freshOrders = await _repo.fetchDriverOrders();
      emit(currentState.copyWith(allOrders: freshOrders));
    } catch (e) {
      emit(OrderError('فشل تحديث القائمة: $e'));
    }
  }
}