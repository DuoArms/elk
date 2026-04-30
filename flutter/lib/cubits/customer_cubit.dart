import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

abstract class CustomerState {}

class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerActionLoading extends CustomerState {
  final String message;
  CustomerActionLoading([this.message = 'جاري المعالجة...']);
}

class CustomersLoaded extends CustomerState {
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final String searchQuery;

  CustomersLoaded(this.customers, {this.searchQuery = ''})
      : filteredCustomers = _filter(customers, searchQuery);

  static List<Customer> _filter(List<Customer> list, String query) {
    if (query.isEmpty) return list;
    final lower = query.toLowerCase();
    return list.where((c) {
      if (c.name.toLowerCase().contains(lower)) return true;
      return c.phones.any((p) => p.phone.contains(lower));
    }).toList();
  }

  CustomersLoaded copyWith({String? searchQuery}) {
    return CustomersLoaded(customers, searchQuery: searchQuery ?? this.searchQuery);
  }
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _repo = CustomerRepository();

  CustomerCubit() : super(CustomerInitial());

  Future<void> loadCustomers() async {
    emit(CustomerLoading());
    try {
      final list = await _repo.fetchCustomers();
      emit(CustomersLoaded(list));
    } catch (e) {
      emit(CustomerError('فشل تحميل الزبائن: ${e.toString()}'));
    }
  }

  Future<void> loadInactiveCustomers() async {
    emit(CustomerLoading());
    try {
      final list = await _repo.fetchInactiveCustomers();
      emit(CustomersLoaded(list));
    } catch (e) {
      emit(CustomerError('فشل تحميل الزبائن المعطلين: ${e.toString()}'));
    }
  }

  void filterCustomers(String query) {
    final current = state;
    if (current is CustomersLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  Future<Customer?> addCustomerWithPayload(Map<String, dynamic> payload) async {
    emit(CustomerActionLoading('جاري إضافة الزبون...'));
    try {
      final newCustomer = await _repo.createCustomerWithPayload(payload);
      addNewCustomerToState(newCustomer);
      await loadCustomers();
      return newCustomer;
    } catch (e) {
      emit(CustomerError('فشل إضافة الزبون: ${e.toString()}'));
      return null;
    }
  }

  Future<Customer?> addCustomer(Customer customer, {String? password}) async {
    final payload = {
      'full_name': customer.name,
      'primary_phone': customer.primaryPhone ?? '',
      'password': password ?? '12345678',
      'name': customer.name,
      'notes': customer.notes,
      'balance': customer.balance,
      'additional_phones': customer.phones.map((p) => {'phone': p.phone}).toList(),
      'addresses': customer.addresses.map((a) => {
        'address': a.addressText,
        'label': a.label,
      }).toList(),
    };
    return addCustomerWithPayload(payload);
  }

  Future<void> updateCustomer(int id, Customer customer) async {
    emit(CustomerActionLoading('جاري تحديث الزبون...'));
    try {
      await _repo.updateCustomer(id, customer);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError('فشل تحديث الزبون: ${e.toString()}'));
    }
  }

  void _removeCustomerFromCurrentList(int id) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      final updatedList = List<Customer>.from(currentState.customers)..removeWhere((c) => c.id == id);
      emit(CustomersLoaded(updatedList, searchQuery: currentState.searchQuery));
    }
  }

  Future<void> deactivateCustomer(int id) async {
    emit(CustomerActionLoading('جاري تعطيل الزبون...'));
    try {
      await _repo.deleteCustomer(id);
      _removeCustomerFromCurrentList(id);
      loadInactiveCustomers();
    } catch (e) {
      emit(CustomerError('فشل تعطيل الزبون: ${e.toString()}'));
    }
  }

  Future<void> reactivateCustomer(int id) async {
    emit(CustomerActionLoading('جاري إعادة التفعيل...'));
    try {
      await _repo.reactivateCustomer(id);
      _removeCustomerFromCurrentList(id);
      loadCustomers();
    } catch (e) {
      emit(CustomerError('فشل إعادة التفعيل: ${e.toString()}'));
    }
  }

  Future<void> deleteCustomer(int id) => deactivateCustomer(id);

  void clearSearch() {
    final current = state;
    if (current is CustomersLoaded) {
      emit(current.copyWith(searchQuery: ''));
    }
  }

  void addNewCustomerToState(Customer newCustomer) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      final updatedList = List<Customer>.from(currentState.customers)..add(newCustomer);
      emit(CustomersLoaded(updatedList, searchQuery: currentState.searchQuery));
    }
  }
}