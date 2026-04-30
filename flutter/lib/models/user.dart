enum UserRole { admin, office, driver, accountant, store, customer }

class User {
  final int id;
  final String phone;
  final String fullName;
  final UserRole role;
  final bool isActive;
  String? token; // يمكن تخزينه مؤقتاً

  User({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      fullName: json['full_name'],
      role: _parseRole(json['role']),
      isActive: json['is_active'] ?? true,
      token: json['access_token'], // قد يأتي أحياناً داخل user
    );
  }

  static UserRole _parseRole(String role) {
    return UserRole.values.firstWhere(
          (e) => e.name == role,
      orElse: () => UserRole.customer,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'role': role.name,
    'is_active': isActive,
  };
}