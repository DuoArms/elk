import '../models/customer.dart';
import '../models/customer_phone.dart';
import '../models/address.dart';
import '../services/api_service.dart';

class CustomerRepository {
  final ApiService _api = ApiService();

  Future<List<Customer>> fetchCustomers() async {
    final data = await _api.get('customers?is_active=1');
    List dataList;
    if (data is List) {
      dataList = data;
    } else if (data is Map && data.containsKey('data')) {
      dataList = data['data'] as List;
    } else {
      return [];
    }
    return dataList.map((json) => Customer.fromJson(json)).toList();
  }

  Future<List<Customer>> fetchInactiveCustomers() async {
    try {
      final response = await _api.get('customers?is_active=0');
      List data;
      if (response is List) {
        data = response;
      } else if (response is Map && response.containsKey('data')) {
        data = response['data'] as List;
      } else {
        return [];
      }
      return data.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Customer> createCustomerWithPayload(Map<String, dynamic> payload) async {
    print('📦 Customer create payload: $payload');
    try {
      final response = await _api.post('customers', payload);
      print('✅ Full response: $response');

      if (response == null) {
        throw Exception('الخادم لم يعد أي بيانات');
      }

      // إذا كانت الاستجابة تحتوي على 'message' و 'errors' فهذا خطأ
      if (response is Map && response.containsKey('message') && response.containsKey('errors')) {
        final errors = response['errors'];
        String errorMsg = response['message'];
        if (errors is Map) {
          errorMsg = errors.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('; ');
        }
        throw Exception(errorMsg);
      }

      // إذا كانت الاستجابة تحتوي على 'error' فقط
      if (response is Map && response.containsKey('error')) {
        throw Exception(response['error']);
      }

      Map<String, dynamic> customerData;
      if (response is Map && response.containsKey('data') && response['data'] is Map) {
        customerData = response['data'] as Map<String, dynamic>;
      } else if (response is Map && response.containsKey('customer') && response['customer'] is Map) {
        customerData = response['customer'] as Map<String, dynamic>;
      } else if (response is Map && response.containsKey('id')) {
        customerData = response as Map<String, dynamic>;
      } else {
        throw Exception('تنسيق استجابة غير معروف: $response');
      }

      if (customerData['id'] == null) {
        throw Exception('الاستجابة لا تحتوي على معرف الزبون');
      }

      final newCustomer = Customer.fromJson(customerData);
      if (newCustomer.id == 0) {
        throw Exception('معرف الزبون غير صالح');
      }
      return newCustomer;
    } catch (e) {
      print('❌ Error creating customer: $e');
      rethrow;
    }
  }

  Future<Customer> createCustomer(Customer customer, {String? password}) async {
    final primaryPhone = customer.primaryPhone;
    if (primaryPhone == null || primaryPhone.isEmpty) {
      throw Exception('رقم الهاتف الأساسي مطلوب');
    }

    final requestData = <String, dynamic>{
      'full_name': customer.name,
      'name': customer.name,
      'primary_phone': primaryPhone,
      'password': password ?? '12345678',
      'notes': customer.notes ?? '',
      'balance': customer.balance,
    };

    if (customer.phones.isNotEmpty) {
      requestData['additional_phones'] = customer.phones.map((p) => {'phone': p.phone}).toList();
    }

    if (customer.addresses.isNotEmpty) {
      requestData['addresses'] = customer.addresses.map((addr) {
        final addrData = <String, dynamic>{
          'address': addr.addressText,
          'label': addr.label,
        };
        if (addr.latitude != null && addr.longitude != null) {
          addrData['location'] = [addr.longitude, addr.latitude];
        }
        return addrData;
      }).toList();
    }

    requestData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    return createCustomerWithPayload(requestData);
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final data = <String, dynamic>{
      'name': customer.name,
      'full_name': customer.name,
      'notes': customer.notes,
      'is_active': customer.isActive,
    };

    if (customer.primaryPhone != null && customer.primaryPhone!.isNotEmpty) {
      data['primary_phone'] = customer.primaryPhone;
    }

    if (customer.phones.isNotEmpty) {
      data['phones'] = customer.phones.map((p) => {'phone': p.phone}).toList();
    } else {
      data['phones'] = [];
    }

    if (customer.addresses.isNotEmpty) {
      data['addresses'] = customer.addresses.map((a) => a.toJson()).toList();
    } else {
      data['addresses'] = [];
    }

    data.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    print('📦 Update payload for id $id: $data');
    final response = await _api.put('customers/$id', data);
    print('✅ Update response: $response');
    return Customer.fromJson(response);
  }

  Future<void> deleteCustomer(int id) async {
    await _api.delete('customers/$id');
  }

  Future<void> reactivateCustomer(int id) async {
    await _api.post('customers/$id/reactivate', {});
  }

  Future<CustomerPhone?> addCustomerPhone(int customerId, String phone) async {
    final response = await _api.post('customers/$customerId/phones', {'phone': phone});
    if (response == null) return null;
    return CustomerPhone.fromJson(response);
  }

  Future<Address?> addCustomerAddress(int customerId, String address, {String? label, double? lat, double? lng}) async {
    final data = {
      'address': address,
      if (label != null) 'label': label,
      if (lat != null && lng != null) 'location': [lng, lat],
    };
    final response = await _api.post('customers/$customerId/addresses', data);
    if (response == null) return null;
    return Address.fromJson(response);
  }
}