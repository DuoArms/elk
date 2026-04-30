class Address {
  final int? id;
  final String label;
  final String addressText;
  final double? latitude;
  final double? longitude;

  Address({
    this.id,
    required this.label,
    required this.addressText,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
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
    return Address(
      id: _toInt(json['id']),
      label: json['label']?.toString() ?? '',
      addressText: json['address']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'label': label,
      'address': addressText,
      // لا نرسل location أبداً لأننا لا نملك إحداثيات
    };
  }
}