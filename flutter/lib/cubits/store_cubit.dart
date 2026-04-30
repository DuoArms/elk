import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/store.dart';
import '../services/api_service.dart';

abstract class StoreState {}
class StoreInitial extends StoreState {}
class StoresLoading extends StoreState {}
class StoresLoaded extends StoreState {
  final List<Store> stores;
  StoresLoaded(this.stores);
}
class StoreError extends StoreState {
  final String message;
  StoreError(this.message);
}

class StoreCubit extends Cubit<StoreState> {
  final ApiService _api = ApiService();

  StoreCubit() : super(StoreInitial());

  Future<void> loadStores({int? storeTypeId}) async {
    emit(StoresLoading());
    try {
      final endpoint = storeTypeId != null ? 'stores?store_type_id=$storeTypeId' : 'stores';
      final response = await _api.get(endpoint);
      List<Store> stores = [];

      if (response is List) {
        stores = response.map((json) => Store.fromJson(json)).toList();
      } else if (response is Map) {
        List list;
        if (response.containsKey('data') && response['data'] is List) {
          list = response['data'] as List;
        } else if (response.containsKey('results') && response['results'] is List) {
          list = response['results'] as List;
        } else if (response.containsKey('items') && response['items'] is List) {
          list = response['items'] as List;
        } else {
          throw Exception('لا يمكن العثور على قائمة المتاجر');
        }
        stores = list.map((json) => Store.fromJson(json)).toList();
      } else {
        throw Exception('تنسيق استجابة غير صالح');
      }

      emit(StoresLoaded(stores));
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }
}