// lib/cubits/accounting_state.dart
import '../models/balance_summary.dart';

abstract class AccountingState {}

class AccountingInitial extends AccountingState {}
class AccountingLoading extends AccountingState {}

class DashboardStatsLoaded extends AccountingState {
  final BalanceSummary summary;
  DashboardStatsLoaded(this.summary);
}

class CustomersBalanceLoaded extends AccountingState {
  final List<Map<String, dynamic>> customers;
  CustomersBalanceLoaded(this.customers);
}

class DriversBalanceLoaded extends AccountingState {
  final List<Map<String, dynamic>> drivers;
  DriversBalanceLoaded(this.drivers);
}

class StoresBalanceLoaded extends AccountingState {
  final List<Map<String, dynamic>> stores;
  StoresBalanceLoaded(this.stores);
}

class TransactionsLoaded extends AccountingState {
  final List<Map<String, dynamic>> transactions;
  final bool hasMore;
  TransactionsLoaded(this.transactions, {this.hasMore = true});
}

class TransactionCreated extends AccountingState {}
class StorePurchasesLoaded extends AccountingState {
  final List<Map<String, dynamic>> purchases;
  StorePurchasesLoaded(this.purchases);
}
class AccountingError extends AccountingState {
  final String message;
  AccountingError(this.message);
}