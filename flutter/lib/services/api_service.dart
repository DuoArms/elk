import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static String? customBaseUrl;

  static String get baseUrl {

      return 'https://site50792-8anj7m.scloudsite101.com/api';

  }

  String? _token;
  static const String _tokenKey = 'access_token';

  // ========== إدارة التوكن ==========
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);

    if (_token != null) {
      _token = _token!.trim(); // مهم
    }

    print('🔑 Token loaded: $_token');
  }

  Map<String, String> get headers {
    print('🔐 Current Token: $_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  Future<Map<String, dynamic>> updateOfficeUser(int id, Map<String, dynamic> data) async {
    final response = await put('admin/office-users/$id', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث مستخدم المكتب');
  }

  Future<void> deleteOfficeUser(int id) async {
    await delete('admin/office-users/$id');
  }
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  bool get isAuthenticated => _token != null;

  // ========== دوال HTTP مع تسجيل مفصّل ==========
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    await loadToken();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$cleanEndpoint';
    print('📤 POST $url');
    print('📦 Headers: $headers');
    print('📦 Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    await loadToken();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    var uri = Uri.parse('$baseUrl$cleanEndpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    print('📤 GET $uri');
    print('📦 Headers: $headers');

    final response = await http.get(uri, headers: headers);
    return _handleResponse(response, endpoint);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    await loadToken();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$cleanEndpoint';
    print('📤 PUT $url');
    print('📦 Body: ${jsonEncode(body)}');

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }

  Future<dynamic> delete(String endpoint) async {
    await loadToken();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$cleanEndpoint';
    print('📤 DELETE $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );
    return _handleResponse(response, endpoint);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    await loadToken();
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$cleanEndpoint';
    print('📤 PATCH $url');
    print('📦 Body: ${jsonEncode(body)}');

    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint);
  }

  dynamic _handleResponse(http.Response response, String endpoint) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      body = {'message': 'خطأ في معالجة البيانات: ${response.body}'};
    }

    print('📥 Response ($endpoint): ${response.statusCode}');
    print('📥 Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = body['message'] ?? 'حدث خطأ';
    if (body.containsKey('errors')) {
      final errors = body['errors'];
      if (errors is Map) {
        errorMessage = errors.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('; ');
      } else if (errors is String) {
        errorMessage = errors;
      }
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  // ========== دوال الزبائن (Customers) ==========
  Future<List<dynamic>> getCustomers() async {
    final response = await get('customers');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للزبائن');
  }

  Future<List<dynamic>> getInactiveCustomers() async {
    final response = await get('customers/inactive');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للزبائن المعطلين');
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final response = await post('customers', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء الزبون');
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await put('customers/$id', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث الزبون');
  }

  Future<void> deleteCustomer(int id) async {
    await delete('customers/$id');
  }

  Future<void> reactivateCustomer(int id) async {
    await put('customers/$id/reactivate', {});
  }

  Future<Map<String, dynamic>> addCustomerAddress(int customerId, Map<String, dynamic> data) async {
    final response = await post('customers/$customerId/addresses', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع');
  }

  Future<Map<String, dynamic>> addCustomerPhone(int customerId, Map<String, dynamic> data) async {
    final response = await post('customers/$customerId/phones', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع');
  }

  // ========== دوال الطلبات (Orders) ==========
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await post('orders', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء الطلب');
  }

  Future<List<dynamic>> getOrders() async {
    final response = await get('orders');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للطلبات');
  }

  Future<Map<String, dynamic>> updateOrder(int orderId, Map<String, dynamic> data) async {
    final response = await put('orders/$orderId', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث الطلب');
  }

  Future<void> deleteOrder(int orderId) async {
    await delete('orders/$orderId');
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final response = await put('admin/orders/$orderId/status', {'status': status});
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع');
  }

  /// تحديث عنصر محدد في الطلب (يستخدمه السائق والمكتب)
  Future<Map<String, dynamic>> updateOrderItem(int orderId, int itemId, Map<String, dynamic> data) async {
    final response = await put('orders/$orderId/items/$itemId', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('item') && response['item'] is Map) {
        return response['item'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث عنصر الطلب');
  }

  /// تحديث عنصر في طلب السائق (نفس الوظيفة لكن بمسار مختلف للتوافق)
  Future<Map<String, dynamic>> updateDriverOrderItem(int orderId, int itemId, Map<String, dynamic> data) async {
    final response = await put('driver/orders/$orderId/items/$itemId', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('item') && response['item'] is Map) {
        return response['item'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث عنصر الطلب');
  }

  Future<void> notifyOrderRejected(int orderId, int driverId) async {
    await post('driver/orders/$orderId/reject-notify', {'driver_id': driverId});
  }

  // ========== دوال الإشعارات (Notifications) ==========
  Future<List<dynamic>> getNotifications({bool? isRead}) async {
    final queryParams = <String, String>{};
    if (isRead != null) {
      queryParams['is_read'] = isRead ? '1' : '0';
    }
    final response = await get('notifications', queryParams: queryParams);
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    return response as List;
  }

  Future<void> markNotificationAsRead(int id) async {
    await patch('notifications/$id/read', {});
  }

  Future<void> markAllNotificationsRead() async {
    await patch('notifications/mark-all-read', {});
  }

  Future<int> getUnreadNotificationsCount() async {
    final response = await get('notifications/unread-count');
    return response['unread_count'] ?? 0;
  }

  // ========== دوال المعاملات المالية (Transactions) ==========
  Future<List<dynamic>> getTransactions() async {
    final response = await get('transactions');
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    return response as List;
  }

  // ========== دوال السائقين (Drivers) ==========
  Future<List<dynamic>> getDrivers() async {
    final response = await get('drivers');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للسائقين');
  }

  // ========== دوال أنواع المتاجر (Store Types) ==========
  Future<List<dynamic>> getStoreTypes() async {
    final response = await get('store-types');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لأنواع المتاجر');
  }

  Future<Map<String, dynamic>> createStoreType(Map<String, dynamic> data) async {
    final response = await post('store-types', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء نوع المتجر');
  }

  Future<Map<String, dynamic>> updateStoreType(int id, Map<String, dynamic> data) async {
    final response = await put('store-types/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث نوع المتجر');
  }

  Future<void> deleteStoreType(int id) async {
    await delete('store-types/$id');
  }

  // ========== دوال المتاجر (Stores) ==========
  Future<List<dynamic>> getStores({int? storeTypeId}) async {
    final endpoint = storeTypeId != null ? 'stores?store_type_id=$storeTypeId' : 'stores';
    final response = await get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للمتاجر');
  }

  Future<Map<String, dynamic>> createStore(Map<String, dynamic> data) async {
    final response = await post('stores', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء المتجر');
  }

  Future<Map<String, dynamic>> updateStore(int id, Map<String, dynamic> data) async {
    final response = await put('stores/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث المتجر');
  }

  Future<void> deleteStore(int id) async {
    await delete('stores/$id');
  }

  /// تحليلات المتجر (مشتريات)
  Future<List<dynamic>> getStoresWithTotalPurchases() async {
    final response = await get('stores/total-purchases');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) return data;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لمشتريات المتاجر');
  }

  Future<Map<String, dynamic>> getStoreMonthlyPurchases(int storeId, {int? month, int? year}) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    final queryString = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    final response = await get('stores/$storeId/monthly-purchases$queryString');
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع');
  }

  // ========== دوال المنتجات (Products) ==========
  Future<List<dynamic>> getProducts({int? storeTypeId}) async {
    final endpoint = storeTypeId != null ? 'products?store_type_id=$storeTypeId' : 'products';
    final response = await get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للمنتجات');
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await post('products', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء المنتج');
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await put('products/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث المنتج');
  }

  Future<void> deleteProduct(int id) async {
    await delete('products/$id');
  }

  // ========== دوال الوحدات (Units) ==========
  Future<List<dynamic>> getUnits({int? storeTypeId}) async {
    final endpoint = storeTypeId != null ? 'units?store_type_id=$storeTypeId' : 'units';
    final response = await get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للوحدات');
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final response = await post('units', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء الوحدة');
  }

  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> data) async {
    final response = await put('units/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث الوحدة');
  }

  Future<void> deleteUnit(int id) async {
    await delete('units/$id');
  }

  // ========== دوال القياسات (Sizes) ==========
  Future<List<dynamic>> getSizes({int? storeTypeId}) async {
    final endpoint = storeTypeId != null ? 'sizes?store_type_id=$storeTypeId' : 'sizes';
    final response = await get(endpoint);
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع للقياسات');
  }

  Future<Map<String, dynamic>> createSize(Map<String, dynamic> data) async {
    final response = await post('sizes', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء القياس');
  }

  Future<Map<String, dynamic>> updateSize(int id, Map<String, dynamic> data) async {
    final response = await put('sizes/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث القياس');
  }

  Future<void> deleteSize(int id) async {
    await delete('sizes/$id');
  }

  // ========== دوال المدير (Admin) والإحصائيات ==========
  Future<Map<String, dynamic>> getStats() async {
    final response = await get('admin/stats');
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع للإحصائيات');
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    return getStats();
  }

  Future<List<dynamic>> getOfficeUsers() async {
    final response = await get('admin/office-users');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لمستخدمي المكتب');
  }

  Future<Map<String, dynamic>> createOfficeUser(Map<String, dynamic> data) async {
    final response = await post('admin/office-users', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء مستخدم المكتب');
  }

  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> data) async {
    final response = await post('admin/drivers', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء السائق');
  }

  Future<Map<String, dynamic>> updateDriver(int id, Map<String, dynamic> data) async {
    final response = await put('admin/drivers/$id', data);
    if (response is Map<String, dynamic>) return response;
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند تحديث السائق');
  }

  Future<void> deleteDriver(int id) async {
    await delete('admin/drivers/$id');
  }

  Future<List<dynamic>> getCustomersWithBalance() async {
    final response = await get('admin/customers/balance');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لأرصدة الزبائن');
  }

  Future<List<dynamic>> getDriversBalances() async {
    final response = await get('admin/drivers/balances');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لأرصدة السائقين');
  }

  Future<List<dynamic>> getStoresBalances() async {
    final response = await get('admin/stores/balances');
    if (response is List) return response;
    if (response is Map && response.containsKey('data')) {
      return response['data'] as List;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع لأرصدة المتاجر');
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await post('admin/transactions', data);
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw ApiException(message: 'تنسيق استجابة غير متوقع عند إنشاء المعاملة');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? rawBody;
  ApiException({required this.message, this.statusCode, this.rawBody});

  @override
  String toString() => message;
}