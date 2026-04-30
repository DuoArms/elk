// lib/screens/accountant/customers_balance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';

class CustomersBalanceScreen extends StatelessWidget {
  const CustomersBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تحميل البيانات عند دخول الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountingCubit>().loadCustomersBalance();
    });

    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is CustomersBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadCustomersBalance(),
            child: ListView.builder(
              itemCount: state.customers.length,
              itemBuilder: (_, i) {
                final c = state.customers[i];
                final name = c['name'] ?? 'زبون ${c['id']}';
                final totalBalance = (c['balance'] as num?)?.toDouble() ?? 0.0;
                final baseBalance = (c['base_balance'] as num?)?.toDouble() ?? 0.0;
                final ordersDebt = (c['orders_debt'] as num?)?.toDouble() ?? 0.0;

                return ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرصيد الإجمالي: ${totalBalance.toStringAsFixed(2)} ل.س'),
                      if (ordersDebt != 0)
                        Text(
                          '  (منها ديون طلبات: ${ordersDebt.toStringAsFixed(2)} ل.س)',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    totalBalance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: totalBalance >= 0 ? Colors.green : Colors.red,
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
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}