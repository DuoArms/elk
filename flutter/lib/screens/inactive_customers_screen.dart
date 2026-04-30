import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/customer_cubit.dart';
import '../models/customer.dart';
import 'customer_details_screen.dart';

const Color _primaryColor = Color(0xFF54d4dd);

class InactiveCustomersScreen extends StatelessWidget {
  const InactiveCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerCubit()..loadInactiveCustomers(),
      child: const InactiveCustomersView(),
    );
  }
}

class InactiveCustomersView extends StatefulWidget {
  const InactiveCustomersView({super.key});

  @override
  State<InactiveCustomersView> createState() => _InactiveCustomersViewState();
}

class _InactiveCustomersViewState extends State<InactiveCustomersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الزبائن المعطلون',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: _primaryColor.withOpacity(0.3),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, _primaryColor.withOpacity(0.15)],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<CustomerCubit>().filterCustomers(value);
                  },
                  style: TextStyle(color: Colors.grey[800]),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو رقم الهاتف...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<CustomerCubit, CustomerState>(
                  builder: (context, state) {
                    if (state is CustomerLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      );
                    }
                    if (state is CustomerError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'خطأ: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<CustomerCubit>().loadInactiveCustomers(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is CustomersLoaded) {
                      final customers = state.filteredCustomers;
                      if (customers.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا يوجد زبائن معطلون',
                            style: TextStyle(color: Colors.black54, fontSize: 18),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: customers.length,
                        itemBuilder: (ctx, index) {
                          final customer = customers[index];
                          return InactiveCustomerCard(customer: customer);
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InactiveCustomerCard extends StatelessWidget {
  final Customer customer;

  const InactiveCustomerCard({super.key, required this.customer});

  void _confirmReactivate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تفعيل الزبون'),
        content: Text('هل أنت متأكد من إعادة تفعيل "${customer.name}"؟\n\nسيظهر الزبون مرة أخرى في قائمة الزبائن النشطاء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final cubit = context.read<CustomerCubit>();
              await cubit.reactivateCustomer(customer.id);
              if (cubit.state is! CustomerError) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إعادة تفعيل الزبون بنجاح')),
                  );
                  // ✅ إغلاق الشاشة وإرجاع true لإعلام الشاشة الرئيسية بالتحديث
                  Navigator.pop(context, true);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل إعادة التفعيل: ${(cubit.state as CustomerError).message}')),
                  );
                }
              }
            },
            child: const Text('إعادة تفعيل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPhone = customer.phones.isNotEmpty ? customer.phones.first.phone : 'لا يوجد';
    final primaryAddress = customer.addresses.isNotEmpty
        ? customer.addresses.first.addressText
        : 'لا يوجد عنوان';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.2),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(primaryPhone, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            primaryAddress,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: () => _confirmReactivate(context),
                tooltip: 'إعادة تفعيل',
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}