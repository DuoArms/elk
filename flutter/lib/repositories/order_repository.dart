import 'dart:convert';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderRepository {
  final ApiService _api = ApiService();
  static const String _driverOrdersBase = 'driver/orders';

  Future<List<Order>> fetchOrders() async {
    try {
      final data = await _api.getOrders();
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل جلب الطلبات: $e');
    }
  }

  Future<Order> fetchOrderById(int orderId) async {
    try {
      final response = await _api.get('orders/$orderId');
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('فشل جلب الطلب: $e');
    }
  }

  Future<List<Order>> fetchDriverOrders() async {
    try {
      final response = await _api.get(_driverOrdersBase);
      final List data = (response is Map && response.containsKey('data'))
          ? response['data'] as List
          : response as List;
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('فشل جلب طلبات السائق: $e');
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _api.put('$_driverOrdersBase/$orderId/status', {'status': newStatus});
    } catch (e) {
      throw Exception('فشل تحديث حالة الطلب: $e');
    }
  }

  Future<void> acceptOrder(int orderId) async {
    try {
      await _api.post('$_driverOrdersBase/$orderId/accept', {});
    } catch (e) {
      throw Exception('فشل قبول الطلب: $e');
    }
  }

  Future<void> rejectOrder(int orderId) async {
    try {
      await _api.post('$_driverOrdersBase/$orderId/reject', {});
    } catch (e) {
      throw Exception('فشل رفض الطلب: $e');
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
      final body = <String, dynamic>{};
      if (isAvailable != null) body['is_available'] = isAvailable;
      if (actualPrice != null) body['actual_price'] = actualPrice;

      if (isAvailable == false && (unavailableReason == null || unavailableReason.isEmpty)) {
        body['unavailable_reason'] = 'تم الإبلاغ من السائق';
      } else if (unavailableReason != null) {
        body['unavailable_reason'] = unavailableReason;
      }

      await _api.put('$_driverOrdersBase/$orderId/items/$itemId', body);
    } catch (e) {
      print('Error updating order item: $e');
      rethrow;
    }
  }

  Future<void> addStoreTotal({
    required int orderId,
    required int storeId,
    required double totalAmount,
    String? notes,
  }) async {
    final body = {
      'store_id': storeId,
      'total_amount': totalAmount,
      if (notes != null) 'notes': notes,
    };

    try {
      await _api.post('$_driverOrdersBase/$orderId/store-total', body);
    } catch (e) {
      throw Exception('فشل تسجيل إجمالي المتجر: $e');
    }
  }

  Future<Order> createOrder(Order order) async {
    try {
      final payload = order.toJson();
      const encoder = JsonEncoder.withIndent('  ');
      print('📦 Creating order with payload:');
      print(encoder.convert(payload));

      final response = await _api.createOrder(payload);
      print('✅ Order created successfully: $response');
      return Order.fromJson(response);
    } catch (e) {
      print('❌ Failed to create order: $e');
      throw Exception('فشل إنشاء الطلب: $e');
    }
  }

  Future<Order> updateOrder(Order order) async {
    try {
      final response = await _api.updateOrder(order.id, order.toJson());
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحديث الطلب: $e');
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      await _api.deleteOrder(orderId);
    } catch (e) {
      throw Exception('فشل حذف الطلب: $e');
    }
  }

  // دالة تغيير متجر عنصر
  Future<void> changeItemStore(int orderId, int itemId, int newStoreId) async {
    try {
      await _api.put('orders/$orderId/items/$itemId', {'store_id': newStoreId});
    } catch (e) {
      throw Exception('فشل تغيير المتجر: $e');
    }
  }
}