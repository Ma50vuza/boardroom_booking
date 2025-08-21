import 'package:flutter/foundation.dart';
import 'package:boardroom_booking/models/user.dart';
import 'package:boardroom_booking/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    _setError(null);

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final result = await ApiService.getUserProfile();
        if (result['success']) {
          _user = User.fromJson(result['data']);
          _setLoading(false);
          return true;
        }
      }
    } catch (e) {
      _setError('Failed to check auth status');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.login(email: email, password: password);

      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    _user = null;
    _error = null;
    notifyListeners();
  }
}
