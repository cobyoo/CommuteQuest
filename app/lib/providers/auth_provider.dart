import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  String? _token;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get api => _api;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _api.setToken(_token!);
    }
    notifyListeners();
  }

  Future<bool> signup(String email, String password, String nickname) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _api.signup(email, password, nickname);
      _api.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _api.login(email, password);
      _api.setToken(_token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
