import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';

class StoresBalanceScreen extends StatelessWidget {
  const StoresBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is StoresBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadStoresBalance(),
            child: ListView.builder(
              itemCount: state.stores.length,
              itemBuilder: (_, i) {
                final s = state.stores[i];
                final name = s['name'] ?? 'متجر ${s['id']}';
                final balance = (s['balance'] as num?)?.toDouble() ?? 0.0;
                return ListTile(
                  title: Text(name),
                  subtitle: Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                  trailing: Icon(balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: balance >= 0 ? Colors.green : Colors.red),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) return const Center(child: CircularProgressIndicator());
        if (state is AccountingError) return Center(child: Text(state.message));
        WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AccountingCubit>().loadStoresBalance());
        return const SizedBox();
      },
    );
  }
}