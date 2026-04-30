import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

abstract class StoreTypeState {}
class StoreTypeInitial extends StoreTypeState {}
class StoreTypesLoading extends StoreTypeState {}
class StoreTypesLoaded extends StoreTypeState {
  final List<Map<String, dynamic>> storeTypes;
  StoreTypesLoaded(this.storeTypes);
}
class StoreTypeError extends StoreTypeState {
  final String message;
  StoreTypeError(this.message);
}

class StoreTypeCubit extends Cubit<StoreTypeState> {
  final ApiService _api = ApiService();

  StoreTypeCubit() : super(StoreTypeInitial());

  Future<void> loadStoreTypes() async {
    emit(StoreTypesLoading());
    try {
      final response = await _api.get('store-types');
      List<Map<String, dynamic>> storeTypes = [];

      if (response is List) {
        storeTypes = response.cast<Map<String, dynamic>>();
      } else if (response is Map) {
        if (response.containsKey('data') && response['data'] is List) {
          storeTypes = (response['data'] as List).cast<Map<String, dynamic>>();
        } else if (response.containsKey('results') && response['results'] is List) {
          storeTypes = (response['results'] as List).cast<Map<String, dynamic>>();
        } else if (response.containsKey('items') && response['items'] is List) {
          storeTypes = (response['items'] as List).cast<Map<String, dynamic>>();
        } else {
          throw Exception('لا يمكن العثور على قائمة في الاستجابة');
        }
      } else {
        throw Exception('تنسيق استجابة غير صالح');
      }

      emit(StoreTypesLoaded(storeTypes));
    } catch (e) {
      emit(StoreTypeError(e.toString()));
    }
  }
}