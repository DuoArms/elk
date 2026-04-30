import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/order_cubit.dart';
import '../cubits/store_cubit.dart';
import '../models/store.dart';

class ChangeItemStoreScreen extends StatefulWidget {
  final int orderId;
  final int itemId;
  final int storeTypeId;
  final String productName;
  final String currentStoreName;
  final String? driverName; // اسم السائق (اختياري)

  const ChangeItemStoreScreen({
    super.key,
    required this.orderId,
    required this.itemId,
    required this.storeTypeId,
    required this.productName,
    required this.currentStoreName,
    this.driverName,
  });

  @override
  State<ChangeItemStoreScreen> createState() => _ChangeItemStoreScreenState();
}

class _ChangeItemStoreScreenState extends State<ChangeItemStoreScreen> {
  int? _selectedStoreId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<StoreCubit>().loadStores(storeTypeId: widget.storeTypeId);
  }

  Future<void> _save() async {
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار متجر بديل'), backgroundColor: Colors.red),
      );
      return;
    }

    // منع اختيار نفس المتجر الحالي
    final currentStore = widget.currentStoreName;
    // لا نستطيع مقارنة الأسماء، ولكن يمكن مقارنة المعرف إذا عرفناه، لكننا لا نملك معرف المتجر الحالي
    // لذا سنترك المتابعة

    setState(() => _isSaving = true);
    try {
      await context.read<OrderCubit>().changeItemStore(
        widget.orderId,
        widget.itemId,
        _selectedStoreId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير المتجر وإرسال الإشعار للسائق'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تغيير المتجر: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تغيير متجر المنتج', style: TextStyle(color: Color(0xFF54d4dd), fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة المعلومات
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.driverName != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF54d4dd), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'السائق: ${widget.driverName}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المنتج: ${widget.productName}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.store, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المتجر الحالي: ${widget.currentStoreName}',
                              style: const TextStyle(fontSize: 15, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('اختر متجراً بديلاً:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<StoreCubit, StoreState>(
                  builder: (context, state) {
                    if (state is StoresLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is StoresLoaded) {
                      if (state.stores.isEmpty) {
                        return const Center(child: Text('لا توجد متاجر متاحة لهذا النوع'));
                      }
                      return ListView.builder(
                        itemCount: state.stores.length,
                        itemBuilder: (context, index) {
                          final store = state.stores[index];
                          return RadioListTile<int>(
                            title: Text(store.name),
                            value: store.id,
                            groupValue: _selectedStoreId,
                            onChanged: (value) {
                              setState(() => _selectedStoreId = value);
                            },
                            activeColor: const Color(0xFF54d4dd),
                          );
                        },
                      );
                    }
                    if (state is StoreError) {
                      return Center(child: Text('خطأ: ${state.message}'));
                    }
                    return const SizedBox();
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF54d4dd),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('حفظ التغيير', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}