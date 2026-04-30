import 'address.dart';
import 'customer_phone.dart';

class Customer {
  final int id;
  final String name;
  final String? primaryPhone;        // رقم الهاتف الأساسي (من جدول users أو الحقل primary_phone)
  final List<CustomerPhone> phones;  // الأرقام الإضافية فقط (بدون تكرار الأساسي)
  final List<Address> addresses;
  final String? notes;
  final double balance;
  final int? userId;
  final bool isActive;
  final DateTime? createdAt;

  Customer({
    required this.id,
    required this.name,
    this.primaryPhone,
    required this.phones,
    required this.addresses,
    this.notes,
    this.balance = 0.0,
    this.userId,
    this.isActive = true,
    this.createdAt,
  });

  /// قائمة تجمع الرقم الأساسي (إن وُجد) مع الأرقام الإضافية، بدون تكرار.
  /// تُستخدم للعرض في الواجهات دون تغيير البيانات الأصلية.
  List<CustomerPhone> get allPhones {
    final list = <CustomerPhone>[];
    if (primaryPhone != null && primaryPhone!.isNotEmpty) {
      final alreadyExists = phones.any((p) => p.phone == primaryPhone);
      if (!alreadyExists) {
        list.add(CustomerPhone(phone: primaryPhone!));
      }
    }
    list.addAll(phones);
    return list;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    // 1. استخراج الرقم الأساسي من user.phone أو primary_phone
    String? primaryPhone;
    if (json['user'] != null && json['user'] is Map) {
      primaryPhone = json['user']['phone']?.toString();
    }
    primaryPhone ??= json['primary_phone']?.toString();

    // 2. الأرقام الإضافية فقط (من قائمة phones)
    List<CustomerPhone> phonesList = (json['phones'] as List? ?? [])
        .map((p) => CustomerPhone.fromJson(p as Map<String, dynamic>))
        .toList();

    // 3. إذا لم نجد primaryPhone بعد، نأخذ أول رقم من phones
    if (primaryPhone == null && phonesList.isNotEmpty) {
      primaryPhone = phonesList.first.phone;
    }

    // 4. نحافظ على الفصل: primaryPhone منفصل، phonesList تبقى كما هي
    // (لا نُدخل primaryPhone تلقائياً في phonesList)

    return Customer(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      primaryPhone: primaryPhone,
      phones: phonesList,
      addresses: (json['addresses'] as List? ?? [])
          .map((a) => Address.fromJson(a as Map<String, dynamic>))
          .toList(),
      notes: json['notes']?.toString(),
      balance: _toDouble(json['balance']) ?? 0.0,
      userId: _toInt(json['user_id']),
      isActive: _toBool(json['is_active']) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (primaryPhone != null) 'phone': primaryPhone,   // الحقل الأساسي باسم "phone"
      'phones': phones.map((p) => p.toJson()).toList(),  // الأرقام الإضافية فقط
      'addresses': addresses.map((a) => a.toJson()).toList(),
      if (notes != null) 'notes': notes,
      'balance': balance,
      if (userId != null) 'user_id': userId,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // دوال التحويل المساعدة
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
      return str == 'true' || str == '1';
    }
    return null;
  }
}