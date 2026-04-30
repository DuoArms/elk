class Product {
  final int id;
  final int storeTypeId;
  final String name;
  final int? unitId;
  final String? unitName;
  final double? price;
  final bool isActive;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.storeTypeId,
    required this.name,
    this.unitId,
    this.unitName,
    this.price,
    this.isActive = true,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double? parsedPrice;
    final priceValue = json['price'];
    if (priceValue != null) {
      if (priceValue is num) {
        parsedPrice = priceValue.toDouble();
      } else if (priceValue is String) {
        parsedPrice = double.tryParse(priceValue);
      }
    }

    String? unitName;
    if (json['unit'] != null && json['unit'] is Map) {
      unitName = json['unit']['name'];
    } else if (json['unit_name'] != null) {
      unitName = json['unit_name'] as String?;
    }

    return Product(
      id: json['id'] as int? ?? 0,
      storeTypeId: json['store_type_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      unitId: json['unit_id'] as int?,
      unitName: unitName,
      price: parsedPrice,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'store_id': storeTypeId,
    'name': name,
    'unit_id': unitId,
    'price': price,
    'is_active': isActive,
  };
}