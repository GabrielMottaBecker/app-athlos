import 'package:flutter/material.dart';
import '../data/datasources/atletica_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';
import '../core/network/dio_client.dart';

// ─── Listar Atléticas ─────────────────────────────────────────────────────────
class SuperAdminViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();

  List<AtleticaModel> _atleticas = [];
  bool _isLoading = false;

  List<AtleticaModel> get atleticas => _atleticas;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await DioClient.identidade.get('/atleticas');
      final List<dynamic> items = response.data is List
          ? response.data as List
          : (response.data['data'] ?? response.data['items'] ?? []) as List;
      _atleticas = items.map((e) {
        final json = e as Map<String, dynamic>;
        return AtleticaModel(
          id:                   json['id'] as String? ?? '',  
          name:                 json['nome'] as String? ?? '',
          presidentName:        json['nomePresidente'] as String? ?? '',
          primaryColorValue:    _hexToInt(json['corPrimaria'] as String? ?? '#2563EB'),
          backgroundColorValue: _hexToInt(json['corFundo'] as String? ?? '#F8FAFC'),
        );
      }).toList();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _hexToInt(String hex) {
    final clean = hex.replaceAll('#', '');
    return int.parse('FF$clean', radix: 16);
  }
}

// ─── Criar Atlética + Admin ───────────────────────────────────────────────────
class RegisterAtleticaViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> save({
    required String nome,
    required String presidente,
    required String emailAdmin,
    required String senhaAdmin,
  }) async {
    if (nome.isEmpty || presidente.isEmpty || emailAdmin.isEmpty || senhaAdmin.isEmpty) {
      _error = 'Preencha todos os campos.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Passo 1 — criar a atlética
      final atletica = await _ds.createAtletica(
        nome:           nome,
        nomePresidente: presidente,
        corPrimaria:    '#2563EB',
        corFundo:       '#F8FAFC',
      );

      final atleticaId = atletica['id'] as String;

      // Passo 2 — criar o usuário ADMINISTRADOR vinculado à atlética
      await DioClient.identidade.post('/usuarios', data: {
        'nome':       presidente,
        'email':      emailAdmin,
        'senha':      senhaAdmin,
        'role':       'ADMINISTRADOR',
        'atleticaId': atleticaId,
      });

      return true;
    } catch (e) {
      _error = 'Erro ao criar atlética. Verifique os dados e tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}