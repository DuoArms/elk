import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/driver.dart';
import '../services/api_service.dart';

abstract class DriverState {}

class DriverInitial extends DriverState {}
class DriversLoading extends DriverState {}
class DriversLoaded extends DriverState {
  final List<Driver> drivers;
  DriversLoaded(this.drivers);
}
class DriverError extends DriverState {
  final String message;
  DriverError(this.message);
}
class DriverProfileLoading extends DriverState {}
class DriverProfileLoaded extends DriverState {
  final Driver driver;
  DriverProfileLoaded(this.driver);
}

class DriverCubit extends Cubit<DriverState> {
  final ApiService _api = ApiService();

  DriverCubit() : super(DriverInitial());

  Future<void> loadDrivers() async {
    emit(DriversLoading());
    try {
      final data = await _api.getDrivers();
      final drivers = data.map((json) => Driver.fromJson(json)).toList();
      emit(DriversLoaded(drivers));
    } catch (e) {
      emit(DriverError(e.toString()));
    }
  }

  Future<void> loadDriverProfile() async {
    emit(DriverProfileLoading());
    try {
      final response = await _api.get('driver/profile');
      final driver = Driver.fromJson(response);
      emit(DriverProfileLoaded(driver));
    } catch (e) {
      emit(DriverError('فشل تحميل ملف السائق: $e'));
    }
  }

  Future<void> notifyRejection(int orderId) async {
    final driver = state is DriverProfileLoaded ? (state as DriverProfileLoaded).driver : null;
    if (driver == null) return;
    await _api.post('driver/orders/$orderId/reject-notify', {'driver_id': driver.id});
  }

  Future<void> toggleAvailability() async {
    try {
      await _api.post('driver/toggle-availability', {});
      await loadDriverProfile();
    } catch (e) {
      emit(DriverError('فشل تغيير حالة التوفر: $e'));
    }
  }
}