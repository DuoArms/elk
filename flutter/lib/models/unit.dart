class Unit {
  final int id;
  final String name;
  final int? storeTypeId;
  final DateTime? createdAt;

  Unit({
    required this.id,
    required this.name,
    this.storeTypeId,
    this.createdAt,
  });

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      storeTypeId: _toInt(json['store_type_id']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'store_type_id': storeTypeId,
  };
}

// يمكن استخدام هذا النوع كـ Measurement أيضاً
typedef Measurement = Unit;