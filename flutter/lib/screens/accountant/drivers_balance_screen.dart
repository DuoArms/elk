import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/accounting_cubit.dart';
import '../../cubits/accounting_state.dart';

class DriversBalanceScreen extends StatelessWidget {
  const DriversBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountingCubit, AccountingState>(
      builder: (context, state) {
        if (state is DriversBalanceLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AccountingCubit>().loadDriversBalance(),
            child: ListView.builder(
              itemCount: state.drivers.length,
              itemBuilder: (_, i) {
                final d = state.drivers[i];
                final name = d['name'] ?? 'سائق ${d['id']}';
                final balance = (d['commission_balance'] as num?)?.toDouble() ?? 0.0;
                final commission = (d['commission_percentage'] as num?)?.toDouble() ?? 10.0;
                return ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرصيد: ${balance.toStringAsFixed(2)} ل.س'),
                      Text('العمولة: ${commission.toStringAsFixed(2)}%'),
                    ],
                  ),
                  trailing: Icon(balance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: balance >= 0 ? Colors.green : Colors.red),
                );
              },
            ),
          );
        }
        if (state is AccountingLoading) return const Center(child: CircularProgressIndicator());
        if (state is AccountingError) return Center(child: Text(state.message));
        WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AccountingCubit>().loadDriversBalance());
        return const SizedBox();
      },
    );
  }
}