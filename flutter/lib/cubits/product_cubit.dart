import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import '../services/api_service.dart';

abstract class ProductState {}
class ProductInitial extends ProductState {}
class ProductsLoading extends ProductState {}
class ProductsLoaded extends ProductState {
  final List<Product> products;
  ProductsLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

class ProductCubit extends Cubit<ProductState> {
  final ApiService _api = ApiService();

  ProductCubit() : super(ProductInitial());

  Future<void> loadProducts({int? storeTypeId}) async {
    emit(ProductsLoading());
    try {
      final endpoint = storeTypeId != null
          ? 'products?store_type_id=$storeTypeId'
          : 'products';

      final response = await _api.get(endpoint);
      List<Product> products = [];

      if (response is List) {
        products = response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map) {
        List list;
        if (response.containsKey('data') && response['data'] is List) {
          list = response['data'] as List;
        } else if (response.containsKey('results') && response['results'] is List) {
          list = response['results'] as List;
        } else if (response.containsKey('items') && response['items'] is List) {
          list = response['items'] as List;
        } else {
          throw Exception('لا يمكن العثور على قائمة المنتجات');
        }
        products = list.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('تنسيق استجابة غير متوقع');
      }

      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductError('فشل تحميل المنتجات: $e'));
    }
  }
}