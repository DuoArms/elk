import '../models/user.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _api = ApiService();

  Future<User> login(String phone, String password) async {
    final response = await _api.post('login', {
      'phone': phone,
      'password': password,
    });
    final user = User.fromJson(response['user']);
    user.token = response['access_token'];
    _api.setToken(user.token!);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('logout', {});
    } catch (_) {}
    _api.clearToken();
  }

  Future<User> getCurrentUser() async {
    final response = await _api.get('me');
    return User.fromJson(response);
  }

  bool get isAuthenticated => _api.isAuthenticated;
}