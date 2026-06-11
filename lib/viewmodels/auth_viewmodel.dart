import 'package:flutter/material.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';

enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  AuthState _state = AuthState.idle;
  String? _errorMessage;
  String? _role;

  final _tokenDs = TokenLocalDatasource();
  final _authDs = AuthRemoteDatasource();

  bool get obscurePassword => _obscurePassword;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get role => _role;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Preencha e-mail e senha.';
      _state = AuthState.error;
      notifyListeners();
      return;
    }

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = await _authDs.login(email, password);
      _role = auth.role;
      _state = AuthState.success;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = AuthState.error;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _authDs.logout();
    _state = AuthState.idle;
    _errorMessage = null;
    _role = null;
    notifyListeners();
  }

  Future<String?> getSavedRole() => _tokenDs.getRole();

  void reset() {
    _state = AuthState.idle;
    _errorMessage = null;
    _role = null;
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Erro inesperado. Tente novamente.';
  }
}