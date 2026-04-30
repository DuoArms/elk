// lib/screens/accountant/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل البيانات مرة واحدة فقط
    context.read<AccountingCubit>().loadTransactions(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is TransactionsLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadTransactions(page: 1),
            child: ListView.builder(
              itemCount: state.transactions.length + (state.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == state.transactions.length) {
                  final nextPage = (state.transactions.length ~/ 20) + 1;
                  context.read<AccountingCubit>().loadTransactions(page: nextPage);
                  return const Center(child: CircularProgressIndicator());
                }

                final t = state.transactions[i];
                final type = t['type'] ?? 'معاملة';
                final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
                final notes = t['notes'] ?? '';
                final date = t['created_at'] != null
                    ? DateTime.parse(t['created_at'])
                    : DateTime.now();

                return ListTile(
                  title: Text('$type - ${amount.toStringAsFixed(2)} ل.س'),
                  subtitle: Text(notes),
                  trailing: Text(
                    '${date.year}/${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AccountingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                ElevatedButton(
                  onPressed: () => context.read<AccountingCubit>().loadTransactions(page: 1),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}