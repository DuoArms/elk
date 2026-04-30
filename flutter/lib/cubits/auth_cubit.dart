import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthCubit extends Cubit<User?> {
  final ApiService _api = ApiService();
  AuthCubit() : super(null);

  Future<void> login(String phone, String password) async {
    try {
      final response = await _api.post('login', {'phone': phone, 'password': password});
      final token = response['access_token'];
      final userData = response['user'];
      await _api.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userData['id']);

      emit(User.fromJson(userData));
    } on ApiException catch (e) {
      throw e.message;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('logout', {});
    } catch (_) {}
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    emit(null);
  }

  Future<bool> isLoggedIn() async {
    await _api.loadToken();
    return _api.isAuthenticated;
  }

  Future<void> checkAuth() async {
    await _api.loadToken();
    if (!_api.isAuthenticated) {
      emit(null);
      return;
    }
    try {
      final response = await _api.get('me');
      emit(User.fromJson(response));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', response['id']);
    } catch (_) {
      await _api.clearToken();
      emit(null);
    }
  }
}