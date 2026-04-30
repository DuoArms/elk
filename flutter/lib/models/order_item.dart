class OrderItem {
  int? id;
  int? orderId;
  int? storeId;
  String? description;
  double quantity;
  int? unitId;
  int? sizeId;
  int? productId;
  double? estimatedPrice;
  double? actualPrice;
  bool isAvailable;
  String? unavailableReason;
  String? storeName;
  String? productName;
  String? unitName;
  String? sizeName;          // ✅ الحقل الجديد لعرض اسم القياس
  String itemType;
  int sortOrder;
  String? pickupAddress;
  List<double>? pickupLocation;
  String? pickupPhone;
  String? pickupContactName;
  String? deliveryAddress;
  List<double>? deliveryLocation;
  String? deliveryPhone;
  String? deliveryContactName;
  double? estimatedFee;
  double? actualFee;
  String? invoiceType;
  String? companyName;
  double? estimatedTotal;
  DateTime? dueDate;
  double? actualInvoiceAmount;
  String? notes;

  OrderItem({
    this.id,
    this.orderId,
    this.storeId,
    this.description,
    this.quantity = 1.0,
    this.unitId,
    this.sizeId,
    this.productId,
    this.estimatedPrice,
    this.actualPrice,
    this.isAvailable = true,
    this.unavailableReason,
    this.storeName,
    this.productName,
    this.unitName,
    this.sizeName,           // ✅
    this.itemType = 'product',
    this.sortOrder = 0,
    this.pickupAddress,
    this.pickupLocation,
    this.pickupPhone,
    this.pickupContactName,
    this.deliveryAddress,
    this.deliveryLocation,
    this.deliveryPhone,
    this.deliveryContactName,
    this.estimatedFee,
    this.actualFee,
    this.invoiceType,
    this.companyName,
    this.estimatedTotal,
    this.dueDate,
    this.actualInvoiceAmount,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      storeId: _toInt(json['store_id']),
      description: json['description'],
      quantity: _toDouble(json['quantity']) ?? 1.0,
      unitId: _toInt(json['unit_id']),
      sizeId: _toInt(json['size_id']),
      productId: _toInt(json['product_id']),
      estimatedPrice: _toDouble(json['estimated_price']),
      actualPrice: _toDouble(json['actual_price']),
      isAvailable: json['is_available'] ?? true,
      unavailableReason: json['unavailable_reason'],
      storeName: json['store']?['name'],
      productName: json['product']?['name'],
      unitName: json['unit']?['name'],
      sizeName: json['size']?['name'],   // ✅ محاولة قراءة اسم الحجم من العلاقة
      itemType: json['item_type'] ?? 'product',
      sortOrder: json['sort_order'] ?? 0,
      pickupAddress: json['pickup_address'],
      pickupLocation: _extractCoordinates(json['pickup_location']),
      pickupPhone: json['pickup_phone'],
      pickupContactName: json['pickup_contact_name'],
      deliveryAddress: json['delivery_address'],
      deliveryLocation: _extractCoordinates(json['delivery_location']),
      deliveryPhone: json['delivery_phone'],
      deliveryContactName: json['delivery_contact_name'],
      estimatedFee: _toDouble(json['estimated_fee']),
      actualFee: _toDouble(json['actual_fee']),
      invoiceType: json['invoice_type'],
      companyName: json['company_name'],
      estimatedTotal: _toDouble(json['estimated_total']),
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      actualInvoiceAmount: _toDouble(json['actual_invoice_amount']),
      notes: json['notes'],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
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
      'item_type': itemType,
      if (id != null) 'id': id,
      'order_id': orderId,
      'store_id': storeId,
      'description': description,
      'quantity': quantity,
      'unit_id': unitId,
      'product_id': productId,
      'estimated_price': estimatedPrice,
      'actual_price': actualPrice,
      'is_available': isAvailable,
      'unavailable_reason': unavailableReason,
      'sort_order': sortOrder,
      'pickup_address': pickupAddress,
      'pickup_phone': pickupPhone,
      'pickup_contact_name': pickupContactName,
      'delivery_address': deliveryAddress,
      'delivery_phone': deliveryPhone,
      'delivery_contact_name': deliveryContactName,
      'estimated_fee': estimatedFee,
      'actual_fee': actualFee,
      'invoice_type': invoiceType,
      'company_name': companyName,
      'estimated_total': estimatedTotal,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'actual_invoice_amount': actualInvoiceAmount,
      'notes': notes,
      'size_id': sizeId,
    };
    if (pickupLocation != null && pickupLocation!.length >= 2) {
      map['pickup_location'] = {'type': 'Point', 'coordinates': pickupLocation};
    }
    if (deliveryLocation != null && deliveryLocation!.length >= 2) {
      map['delivery_location'] = {'type': 'Point', 'coordinates': deliveryLocation};
    }
    // لا نرسل sizeName إلى الخادم – إنه حقل عرض فقط
    return map;
  }
}