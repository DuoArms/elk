class Driver {
  final int id;
  final int? userId;
  final String? fullName;
  final String? phone;
  final String? vehicleType;
  final String vehicleOwnership;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final double balance;
  final bool isActive;
  final DateTime? createdAt;
  final double commissionPercentage;

  Driver({
    required this.id,
    this.userId,
    this.fullName,
    this.phone,
    this.vehicleType,
    required this.vehicleOwnership,
    this.isAvailable = true,
    this.currentLat,
    this.currentLng,
    this.balance = 0.0,
    this.isActive = true,
    this.createdAt,
    this.commissionPercentage = 10.0,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    double? lat, lng;
    if (json['current_location'] != null) {
      final loc = json['current_location'];
      if (loc is Map && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          lng = _toDouble(coords[0]);
          lat = _toDouble(coords[1]);
        }
      }
    }

    return Driver(
      id: _toInt(json['id']) ?? 0,
      userId: _toInt(json['user_id']),
      fullName: user?['full_name'] as String?,
      phone: user?['phone'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehicleOwnership: json['vehicle_ownership'] as String? ?? 'own',
      isAvailable: _toBool(json['is_available']) ?? true,
      currentLat: lat,
      currentLng: lng,
      balance: _toDouble(json['balance']) ?? 0.0,
      isActive: _toBool(user?['is_active']) ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      commissionPercentage: _toDouble(json['commission_percentage']) ?? 10.0,
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

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final str = value.toLowerCase();
      return str == 'true' || str == '1' || str == 't';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'vehicle_type': vehicleType,
    'vehicle_ownership': vehicleOwnership,
    'is_available': isAvailable,
    if (currentLat != null && currentLng != null)
      'current_location': [currentLng, currentLat],
  };
}