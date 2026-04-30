import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';

class StorePurchasesScreen extends StatelessWidget {
  const StorePurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is StorePurchasesLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadStorePurchases(),
            child: ListView.builder(
              itemCount: state.purchases.length,
              itemBuilder: (_, i) {
                final s = state.purchases[i];
                final name = s['name'] ?? 'متجر ${s['id']}';
                final total = (s['total_purchases'] as num?)?.toDouble() ?? 0.0;
                return ListTile(
                  title: Text(name),
                  subtitle: Text('إجمالي المشتريات: ${total.toStringAsFixed(2)} ل.س'),
                  trailing: const Icon(Icons.store),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AccountingError) {
          return Center(child: Text(state.message));
        }
        // Initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AccountingCubit>().loadStorePurchases();
        });
        return const SizedBox();
      },
    );
  }
}