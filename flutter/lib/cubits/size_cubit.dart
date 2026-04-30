import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/size.dart';
import '../services/api_service.dart';

abstract class SizeState {}
class SizeInitial extends SizeState {}
class SizesLoading extends SizeState {}
class SizesLoaded extends SizeState {
  final List<Size> sizes;
  SizesLoaded(this.sizes);
}
class SizeError extends SizeState {
  final String message;
  SizeError(this.message);
}

class SizeCubit extends Cubit<SizeState> {
  final ApiService _api = ApiService();

  SizeCubit() : super(SizeInitial());

  Future<void> loadSizes({int? storeTypeId}) async {
    emit(SizesLoading());
    try {
      final endpoint = storeTypeId != null
          ? 'sizes?store_type_id=$storeTypeId'
          : 'sizes';

      final response = await _api.get(endpoint);
      List<Size> sizes = [];

      if (response is List) {
        sizes = response.map((json) => Size.fromJson(json)).toList();
      } else if (response is Map) {
        List list;
        if (response.containsKey('data') && response['data'] is List) {
          list = response['data'] as List;
        } else if (response.containsKey('results') && response['results'] is List) {
          list = response['results'] as List;
        } else if (response.containsKey('items') && response['items'] is List) {
          list = response['items'] as List;
        } else {
          throw Exception('لا يمكن العثور على قائمة القياسات');
        }
        sizes = list.map((json) => Size.fromJson(json)).toList();
      } else {
        throw Exception('تنسيق استجابة غير متوقع');
      }

      emit(SizesLoaded(sizes));
    } catch (e) {
      emit(SizeError('فشل تحميل القياسات: $e'));
    }
  }
}