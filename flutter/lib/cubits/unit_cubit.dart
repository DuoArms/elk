import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

abstract class UnitState {}
class UnitInitial extends UnitState {}
class UnitsLoading extends UnitState {}
class UnitsLoaded extends UnitState {
  final List<Unit> units;
  UnitsLoaded(this.units);
}
class UnitError extends UnitState {
  final String message;
  UnitError(this.message);
}

class UnitCubit extends Cubit<UnitState> {
  final ApiService _api = ApiService();

  UnitCubit() : super(UnitInitial());

  Future<void> loadUnits({int? storeTypeId}) async {
    emit(UnitsLoading());
    try {
      final endpoint = storeTypeId != null ? 'units?store_type_id=$storeTypeId' : 'units';
      developer.log('Loading units from: $endpoint', name: 'UnitCubit');

      final response = await _api.get(endpoint);
      developer.log('Units response: $response', name: 'UnitCubit');

      List<Unit> units = [];

      if (response is List) {
        units = response.map((json) => Unit.fromJson(json)).toList();
      } else if (response is Map) {
        List? list;
        if (response.containsKey('data') && response['data'] is List) {
          list = response['data'];
        } else if (response.containsKey('results') && response['results'] is List) {
          list = response['results'];
        } else if (response.containsKey('items') && response['items'] is List) {
          list = response['items'];
        } else if (response.containsKey('units') && response['units'] is List) {
          list = response['units'];
        } else if (response.containsKey('sizes') && response['sizes'] is List) {
          list = response['sizes'];
        } else {
          for (var value in response.values) {
            if (value is List) {
              list = value;
              break;
            }
          }
        }
        if (list != null) {
          units = list.map((json) => Unit.fromJson(json)).toList();
        } else {
          throw Exception('لا يمكن العثور على قائمة الوحدات في الاستجابة: $response');
        }
      } else {
        throw Exception('تنسيق استجابة غير صالح: نوع الاستجابة ${response.runtimeType}');
      }

      developer.log('Loaded ${units.length} units', name: 'UnitCubit');
      emit(UnitsLoaded(units));
    } catch (e, stack) {
      developer.log('Error loading units', error: e, stackTrace: stack, name: 'UnitCubit');
      emit(UnitError(e.toString()));
    }
  }
}