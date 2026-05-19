import 'package:flutter/material.dart';
import '../../data/datasources/token_local_datasource.dart';
import '../../data/repositories/repositories.dart';

enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  AuthState _state = AuthState.idle;
  String? _errorMessage;
  String? _role;

  final _tokenDs = TokenLocalDatasource();

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

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final members = MemberRepository().getAdminMembers();

      final user = members.firstWhere(
        (m) => m.email == email && m.senha == password,
        orElse: () => throw Exception('E-mail ou senha incorretos.'),
      );

      if (user.isAdmin) {
        _role = 'admin';
      } else if (user.isPresident) {
        _role = 'president';
      } else {
        _role = 'user';
      }

      await _tokenDs.saveTokens(
        access:  'mock_access_${user.id}',
        refresh: 'mock_refresh_${user.id}',
        role:    _role!,
        userId:  user.id.toString(),
      );
      _state = AuthState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = AuthState.error;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenDs.clearTokens();
    _state = AuthState.idle;
    _errorMessage = null;
    _role = null;
    notifyListeners();
  }

  void reset() {
    _state = AuthState.idle;
    _errorMessage = null;
    _role = null;
    notifyListeners();
  }
}