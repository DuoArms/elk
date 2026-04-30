import 'order_item.dart';

enum OrderStatus {
  pending, assigned, accepted, rejected, timeout,
  on_the_way, items_purchased, delivered, cancelled
}

enum PaymentStatus { cash, credit, partial }

class Order {
  final int id;
  final String orderNumber;
  final int? customerId;
  final String? customerName;
  final int? officeUserId;
  final int? driverId;
  final String? driverName;
  final OrderStatus status;
  final double deliveryFee;
  final PaymentStatus paymentStatus;
  final double paidAmount;
  final double remainingAmount;
  final List<double>? pickupLocation;
  final List<double>? deliveryLocation;
  final String? notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final int? customerAddressId;
  final Map<String, dynamic>? customerAddress;
  final String? orderPhones;

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.officeUserId,
    this.driverId,
    this.driverName,
    required this.status,
    required this.deliveryFee,
    required this.paymentStatus,
    required this.paidAmount,
    required this.remainingAmount,
    this.pickupLocation,
    this.deliveryLocation,
    this.notes,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.items = const [],
    this.customerAddressId,
    this.customerAddress,
    this.orderPhones,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final driver = json['driver'];

    return Order(
      id: _toInt(json['id']) ?? 0,
      orderNumber: json['order_number'] ?? '',
      customerId: _toInt(json['customer_id']),
      customerName: customer?['name'] ?? '',
      officeUserId: _toInt(json['office_user_id']),
      driverId: _toInt(json['driver_id']),
      driverName: driver?['user']?['full_name'] ?? '',
      status: _parseOrderStatus(json['status']),
      deliveryFee: _toDouble(json['delivery_fee']) ?? 0.0,
      paymentStatus: _parsePaymentStatus(json['payment_status']),
      paidAmount: _toDouble(json['paid_amount']) ?? 0.0,
      remainingAmount: _toDouble(json['remaining_amount']) ?? 0.0,
      pickupLocation: _extractCoordinates(json['pickup_location']),
      deliveryLocation: _extractCoordinates(json['delivery_location']),
      notes: json['notes'],
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      acceptedAt: _parseDate(json['accepted_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      items: (json['items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
      customerAddressId: _toInt(json['customer_address_id']),
      customerAddress: json['customer_address'] is Map ? json['customer_address'] : null,
      orderPhones: json['order_phones'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static OrderStatus _parseOrderStatus(dynamic status) {
    final str = status.toString();
    return OrderStatus.values.firstWhere((e) => e.name == str, orElse: () => OrderStatus.pending);
  }

  static PaymentStatus _parsePaymentStatus(dynamic status) {
    final str = status.toString();
    return PaymentStatus.values.firstWhere((e) => e.name == str, orElse: () => PaymentStatus.cash);
  }

  static List<double>? _extractCoordinates(dynamic location) {
    if (location == null) return null;
    if (location is Map && location['coordinates'] is List) {
      final coords = location['coordinates'];
      if (coords.length >= 2) {
        final lng = _toDouble(coords[0]);
        final lat = _toDouble(coords[1]);
        if (lng != null && lat != null) return [lng, lat];
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'order_number': orderNumber,
      if (customerId != null) 'customer_id': customerId,
      if (officeUserId != null) 'office_user_id': officeUserId,
      if (driverId != null) 'driver_id': driverId,
      'status': status.name,
      'delivery_fee': deliveryFee,
      'payment_status': paymentStatus.name,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      if (pickupLocation != null && pickupLocation!.length >= 2)
        'pickup_location': {'type': 'Point', 'coordinates': pickupLocation},
      if (deliveryLocation != null && deliveryLocation!.length >= 2)
        'delivery_location': {'type': 'Point', 'coordinates': deliveryLocation},
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (customerAddressId != null) 'customer_address_id': customerAddressId,
      if (orderPhones != null && orderPhones!.isNotEmpty) 'order_phones': orderPhones,
      'items': items.map((i) => i.toJson()).toList(),
    };
    return map;
  }

  static String generateOrderNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 1000000;
    return 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
  }
}