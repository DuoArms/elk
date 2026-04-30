import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/customer_cubit.dart';
import '../models/customer.dart';
import 'add_edit_customer_screen.dart';
import 'customer_details_screen.dart';
import 'inactive_customers_screen.dart';

const Color _primaryColor = Color(0xFF54d4dd);

class CustomerDirectory extends StatelessWidget {
  const CustomerDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerCubit()..loadCustomers(),
      child: const CustomerDirectoryView(),
    );
  }
}

class CustomerDirectoryView extends StatefulWidget {
  const CustomerDirectoryView({super.key});

  @override
  State<CustomerDirectoryView> createState() => _CustomerDirectoryViewState();
}

class _CustomerDirectoryViewState extends State<CustomerDirectoryView> {
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
            'دليل الزبائن',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.person_off),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InactiveCustomersScreen()),
                );
                if (result == true && context.mounted) {
                  context.read<CustomerCubit>().loadCustomers();
                }
              },
              tooltip: 'الزبائن المعطلون',
              color: _primaryColor,
            ),
          ],
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
                              onPressed: () => context.read<CustomerCubit>().loadCustomers(),
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
                            'لا يوجد زبائن نشطاء',
                            style: TextStyle(color: Colors.black54, fontSize: 18),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: customers.length,
                        itemBuilder: (ctx, index) {
                          final customer = customers[index];
                          return CustomerCard(customer: customer);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
            );
            if (result != null) {
              _searchController.clear();
              if (result is Customer) {
                // ✅ إضافة الزبون الجديد يدوياً إلى القائمة فوراً
                context.read<CustomerCubit>().addNewCustomerToState(result);
              } else if (result == true) {
                // تعديل زبون موجود -> نعيد التحميل الكامل للتأكد من التحديثات
                context.read<CustomerCubit>().loadCustomers();
              }
              context.read<CustomerCubit>().clearSearch();
            }
          },
          backgroundColor: _primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

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
                backgroundColor: _primaryColor.withOpacity(0.2),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0] : '?',
                  style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
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
                        if (customer.phones.length > 1)
                          Text(
                            ' +${customer.phones.length - 1}',
                            style: const TextStyle(color: Colors.grey),
                          ),
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
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}