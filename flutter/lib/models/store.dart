class Store {
  final int id;
  final String name;
  final int? storeTypeId;
  final String? storeTypeName;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime? createdAt;
  final double commissionPercentage;
  final double balance;

  Store({
    required this.id,
    required this.name,
    this.storeTypeId,
    this.storeTypeName,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.createdAt,
    this.commissionPercentage = 0.0,
    this.balance = 0.0,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    if (json['location'] != null) {
      final loc = json['location'];
      if (loc is Map && loc['coordinates'] is List) {
        final coords = loc['coordinates'];
        if (coords.length >= 2) {
          lng = _toDouble(coords[0]);
          lat = _toDouble(coords[1]);
        }
      }
    }

    return Store(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      storeTypeId: json['store_type_id'] as int?,
      storeTypeName: json['store_type']?['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      latitude: lat,
      longitude: lng,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      commissionPercentage: _toDouble(json['commission_percentage']) ?? 0.0,
      balance: _toDouble(json['balance']) ?? 0.0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'store_type_id': storeTypeId,
    'phone': phone,
    'address': address,
    'is_active': isActive,
    if (latitude != null && longitude != null)
      'location': [longitude, latitude],
  };
}