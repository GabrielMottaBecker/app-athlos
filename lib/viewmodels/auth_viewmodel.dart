import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }
}
