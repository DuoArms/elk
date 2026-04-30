import '../services/api_service.dart';
import '../models/balance_summary.dart';
import '../models/customer.dart';
import '../models/driver.dart';
import '../models/store.dart';
import '../models/transaction.dart';

class AccountingRepository {
  final ApiService _api = ApiService();

  Future<BalanceSummary> fetchDashboardStats() async {
    final response = await _api.get('accountant/reports/dashboard');
    return BalanceSummary.fromJson(response);
  }

  Future<List<Customer>> fetchCustomersBalance() async {
    final response = await _api.get('accountant/customers/balance');
    final data = response['data'] ?? response;
    return (data as List).map((json) => Customer.fromJson(json)).toList();
  }

  Future<List<Driver>> fetchDriversBalance() async {
    final response = await _api.get('accountant/drivers/balances');
    final data = response['data'] ?? response;
    return (data as List).map((json) => Driver.fromJson(json)).toList();
  }

  Future<List<Store>> fetchStoresBalance() async {
    final response = await _api.get('accountant/stores/balances');
    final data = response['data'] ?? response;
    return (data as List).map((json) => Store.fromJson(json)).toList();
  }

  Future<List<Transaction>> fetchTransactions({int page = 1, String? type}) async {
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    query['page'] = page.toString();
    final response = await _api.get('accountant/transactions', queryParams: query);
    final data = response['data'] ?? response;
    return (data as List).map((json) => Transaction.fromJson(json)).toList();
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    final response = await _api.post('accountant/transactions', data);
    return Transaction.fromJson(response['data'] ?? response);
  }
}