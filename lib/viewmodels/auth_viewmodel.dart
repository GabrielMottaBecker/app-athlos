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

/// Estado isolado para o fluxo de ativação de conta (primeiro acesso do
/// membro). Mantido separado do AuthViewModel para não acoplar a tela de
/// login normal com a lógica de ativação.
enum AtivacaoState { idle, loading, success, error }

class AtivacaoContaViewModel extends ChangeNotifier {
  final _authDs = AuthRemoteDatasource();

  AtivacaoState _state = AtivacaoState.idle;
  String? _errorMessage;
  String? _tokenSessao;
  String? _nomeMembro;
  bool _obscurePassword = true;
  bool _obscureConfirmarSenha = true;
  String? _roleAposAtivar;

  AtivacaoState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get nomeMembro => _nomeMembro;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmarSenha => _obscureConfirmarSenha;
  String? get roleAposAtivar => _roleAposAtivar;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmarSenhaVisibility() {
    _obscureConfirmarSenha = !_obscureConfirmarSenha;
    notifyListeners();
  }

  /// Etapa 1: confirma email + telefone. Em caso de sucesso, guarda o
  /// token de sessão para a etapa 2 e devolve true para a tela navegar.
  Future<bool> verificarAssociado(String email, String telefone) async {
    if (email.trim().isEmpty || telefone.trim().isEmpty) {
      _errorMessage = 'Preencha e-mail e telefone.';
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }

    _state = AtivacaoState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authDs.verificarAssociado(
        email: email.trim(),
        telefone: telefone.trim(),
      );
      _tokenSessao = result.tokenSessao;
      _nomeMembro = result.nome;
      _state = AtivacaoState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }
  }

  /// Etapa 2: define a senha. Em caso de sucesso, o membro já fica logado
  /// (tokens salvos pelo datasource) e a role fica disponível para a tela
  /// decidir para onde navegar.
  Future<bool> definirSenha(String senha, String confirmarSenha) async {
    if (senha.length < 8) {
      _errorMessage = 'A senha precisa ter pelo menos 8 caracteres.';
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }

    if (senha != confirmarSenha) {
      _errorMessage = 'As senhas não coincidem.';
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }

    if (_tokenSessao == null) {
      _errorMessage = 'Sessão expirada. Volte e confirme seu email novamente.';
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }

    _state = AtivacaoState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = await _authDs.definirSenha(
        tokenSessao: _tokenSessao!,
        senha: senha,
      );
      _roleAposAtivar = auth.role;
      _state = AtivacaoState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = AtivacaoState.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AtivacaoState.error) _state = AtivacaoState.idle;
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Erro inesperado. Tente novamente.';
  }
}