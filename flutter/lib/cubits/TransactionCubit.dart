import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

abstract class TransactionState {}
class TransactionInitial extends TransactionState {}
class TransactionsLoading extends TransactionState {}
class TransactionsLoaded extends TransactionState {
  final List<dynamic> transactions;
  TransactionsLoaded(this.transactions);
}
class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

class TransactionCubit extends Cubit<TransactionState> {
  final ApiService _api = ApiService();

  TransactionCubit() : super(TransactionInitial());

  Future<void> loadTransactions() async {
    emit(TransactionsLoading());
    try {
      final transactions = await _api.getTransactions();
      emit(TransactionsLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    await _api.createTransaction(data);
  }
}