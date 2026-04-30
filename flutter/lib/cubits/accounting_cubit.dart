import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import '../models/balance_summary.dart';
import 'accounting_state.dart';

class AccountingCubit extends Cubit<AccountingState> {
  final ApiService _api = ApiService();

  AccountingCubit() : super(AccountingInitial());

  // دالة لتحويل أي بيانات إلى Map<String, dynamic> بشكل تعاودي وآمن
  dynamic _forceStringKeyMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map((e) => MapEntry(
          e.key.toString(),
          _forceStringKeyMap(e.value),
        )),
      );
    } else if (data is List) {
      return data.map((e) => _forceStringKeyMap(e)).toList();
    } else if (data is String) {
      if (data.contains('.')) {
        return double.tryParse(data) ?? data;
      } else {
        return int.tryParse(data) ?? data;
      }
    }
    return data;
  }

  // دالة موحدة لتحليل الاستجابة
  Map<String, dynamic> _parseToMap(dynamic response) {
    dynamic data = response;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return {};
      }
    }
    final converted = _forceStringKeyMap(data);
    if (converted is Map<String, dynamic>) {
      return converted;
    }
    return {};
  }

  List<Map<String, dynamic>> _parseToList(dynamic response) {
    dynamic data = response;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return [];
      }
    }
    List list = [];
    if (data is List) {
      list = data;
    } else if (data is Map) {
      if (data.containsKey('data') && data['data'] is List) {
        list = data['data'];
      } else {
        list = [data];
      }
    } else {
      return [];
    }
    return list.map((e) {
      final converted = _forceStringKeyMap(e);
      if (converted is Map<String, dynamic>) {
        return converted;
      }
      return <String, dynamic>{};
    }).toList();
  }

  Future<void> loadDashboardStats() async {
    emit(AccountingLoading());
    try {
      final response = await _api.get('accounting/dashboard');
      final normalized = _parseToMap(response);
      final summary = BalanceSummary.fromJson(normalized);
      emit(DashboardStatsLoaded(summary));
    } catch (e) {
      emit(AccountingError('فشل تحميل الإحصائيات: $e'));
    }
  }

  Future<void> loadCustomersBalance() async {
    emit(AccountingLoading());
    try {
      final response = await _api.get('accounting/customers/balance');
      final customers = _parseToList(response);
      emit(CustomersBalanceLoaded(customers));
    } catch (e) {
      emit(AccountingError('فشل تحميل أرصدة الزبائن: $e'));
    }
  }

  Future<void> loadStorePurchases() async {
    emit(AccountingLoading());
    try {
      final response = await _api.get('accounting/stores/purchases');
      final purchases = _parseToList(response);
      emit(StorePurchasesLoaded(purchases));
    } catch (e) {
      emit(AccountingError('فشل تحميل مشتريات المتاجر: $e'));
    }
  }

  Future<void> loadDriversBalance() async {
    emit(AccountingLoading());
    try {
      final response = await _api.get('accounting/drivers/balance');
      final drivers = _parseToList(response);
      emit(DriversBalanceLoaded(drivers));
    } catch (e) {
      emit(AccountingError('فشل تحميل أرصدة السائقين: $e'));
    }
  }

  Future<void> loadStoresBalance() async {
    emit(AccountingLoading());
    try {
      final response = await _api.get('accounting/stores/balance');
      final stores = _parseToList(response);
      emit(StoresBalanceLoaded(stores));
    } catch (e) {
      emit(AccountingError('فشل تحميل أرصدة المتاجر: $e'));
    }
  }

  Future<void> loadTransactions({int page = 1, String? type}) async {
    if (page == 1) emit(AccountingLoading());
    try {
      final query = {'page': page.toString()};
      if (type != null) query['type'] = type;
      final response = await _api.get('accounting/transactions', queryParams: query);
      final transactions = _parseToList(response);
      final current = state;
      if (current is TransactionsLoaded && page > 1) {
        emit(TransactionsLoaded([...current.transactions, ...transactions],
            hasMore: transactions.isNotEmpty));
      } else {
        emit(TransactionsLoaded(transactions, hasMore: transactions.isNotEmpty));
      }
    } catch (e) {
      emit(AccountingError('فشل تحميل المعاملات: $e'));
    }
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    emit(AccountingLoading());
    try {
      await _api.post('accounting/transactions', data);
      emit(TransactionCreated());
      await loadDashboardStats();
      await loadTransactions();
    } catch (e) {
      emit(AccountingError('فشل إنشاء المعاملة: $e'));
    }
  }
}