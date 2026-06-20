import 'package:flutter/material.dart';
import '../data/datasources/token_local_datasource.dart';
import '../core/network/dio_client.dart';

class PerfilViewModel extends ChangeNotifier {
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _nome = '';
  String _email = '';
  String _cargo = 'Membro';
  String _role = '';
  bool _isLoading = false;

  String get nome => _nome;
  String get email => _email;
  String get cargo => _cargo;
  String get role => _role;
  bool get isLoading => _isLoading;

  String get initials => _nome.trim().isEmpty
      ? '?'
      : _nome.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();

  PerfilViewModel();

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId     = await _tokenDs.getUserId();
      final atleticaId = await _tokenDs.getAtleticaId();
      _role            = await _tokenDs.getRole() ?? 'MEMBRO';

      if (userId == null) return;

      // Busca dados do usuário
      final userResponse = await DioClient.identidade.get('/usuarios/$userId');
      _nome  = userResponse.data['nome']  as String? ?? '';
      _email = userResponse.data['email'] as String? ?? '';

      // Busca cargo do associado se tiver atleticaId
      if (atleticaId != null) {
        try {
          final assocResponse = await DioClient.associacao
              .get('/associados/atletica/$atleticaId');
          final List<dynamic> items = assocResponse.data is List
              ? assocResponse.data as List
              : (assocResponse.data['data'] ?? assocResponse.data['items'] ?? []) as List;

          final associado = items.firstWhere(
            (a) => a['email'] == _email,
            orElse: () => null,
          );
          if (associado != null) {
            _cargo = associado['cargo']?['nome'] as String? ?? _roleLabel(_role);
          } else {
            _cargo = _roleLabel(_role);
          }
        } catch (_) {
          _cargo = _roleLabel(_role);
        }
      } else {
        _cargo = _roleLabel(_role);
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMINISTRADOR': return 'Administrador';
      case 'SUPER_ADMIN':   return 'Super Admin';
      default:              return 'Membro';
    }
  }
}