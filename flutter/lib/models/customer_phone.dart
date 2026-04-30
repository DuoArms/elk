class CustomerPhone {
  final int? id;
  final String phone;

  CustomerPhone({this.id, required this.phone});

  factory CustomerPhone.fromJson(Map<String, dynamic> json) {
    return CustomerPhone(
      id: _toInt(json['id']),
      phone: json['phone']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
  };
}