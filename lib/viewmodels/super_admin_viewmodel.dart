import 'package:flutter/material.dart';
import '../data/datasources/atletica_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';
import '../core/network/dio_client.dart';

// ─── Listar / gerenciar Atléticas ─────────────────────────────────────────────
class SuperAdminViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();

  List<AtleticaModel> _atleticas = [];
  bool _isLoading = false;
  String? _error;

  List<AtleticaModel> get atleticas => _atleticas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
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
          status:               json['status'] as String? ?? 'ATIVO',
        );
      }).toList();
    } catch (e) {
      _error = 'Erro ao carregar atléticas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAtletica(String id, {required String nome, required String presidente}) async {
    try {
      await _ds.updateAtletica(id, {
        'nome': nome,
        'nomePresidente': presidente,
      });
      final idx = _atleticas.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _atleticas[idx] = _atleticas[idx].copyWith(name: nome, presidentName: presidente);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changeStatus(String id, String status) async {
    try {
      await _ds.changeStatus(id, status);
      final idx = _atleticas.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _atleticas[idx] = _atleticas[idx].copyWith(status: status);
        notifyListeners();
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('>>> ERRO changeStatus atlética: $e');
      return false;
    }
  }

  Future<bool> deleteAtletica(String id) async {
    try {
      await _ds.deleteAtletica(id);
      _atleticas.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('>>> ERRO deleteAtletica: $e');
      return false;
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
      final atletica = await _ds.createAtletica(
        nome:           nome,
        nomePresidente: presidente,
        corPrimaria:    '#2563EB',
        corFundo:       '#F8FAFC',
      );

      final atleticaId = atletica['id'] as String;

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

// ─── Editar Atlética ──────────────────────────────────────────────────────────
class EditAtleticaViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> save({
    required String id,
    required String nome,
    required String presidente,
    required String corPrimaria,
    required String corFundo,
  }) async {
    if (nome.isEmpty || presidente.isEmpty) {
      _error = 'Preencha nome e presidente.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _ds.updateAtletica(id, {
        'nome': nome,
        'nomePresidente': presidente,
        'corPrimaria': corPrimaria,
        'corFundo': corFundo,
      });
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar atlética.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
