class NotificationModel {
  final int id;
  final String? type;
  final String? title;
  final String? body;
  final bool isRead;
  final DateTime createdAt;
  final int? orderId;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? product;
  final Map<String, dynamic>? store;
  final int? driverId;
  final int? productId;
  final int? storeId;
  final int? itemId;
  final int? storeTypeId;

  NotificationModel({
    required this.id,
    this.type,
    this.title,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    this.order,
    this.driver,
    this.sender,
    this.product,
    this.store,
    this.driverId,
    this.productId,
    this.storeId,
    this.itemId,
    this.storeTypeId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      orderId: json['order_id'],
      order: json['order'],
      driver: json['driver'],
      sender: json['sender'],
      product: json['product'],
      store: json['store'],
      driverId: json['driver_id'],
      productId: json['product_id'],
      storeId: json['store_id'],
      itemId: json['item_id'],
      storeTypeId: json['store_type_id'],
    );
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    int? orderId,
    Map<String, dynamic>? order,
    Map<String, dynamic>? driver,
    Map<String, dynamic>? sender,
    Map<String, dynamic>? product,
    Map<String, dynamic>? store,
    int? driverId,
    int? productId,
    int? storeId,
    int? itemId,
    int? storeTypeId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      orderId: orderId ?? this.orderId,
      order: order ?? this.order,
      driver: driver ?? this.driver,
      sender: sender ?? this.sender,
      product: product ?? this.product,
      store: store ?? this.store,
      driverId: driverId ?? this.driverId,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      itemId: itemId ?? this.itemId,
      storeTypeId: storeTypeId ?? this.storeTypeId,
    );
  }
}