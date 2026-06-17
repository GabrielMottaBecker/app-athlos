import 'package:flutter/material.dart';
import '../data/datasources/atletica_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';

class AtleticaSettingsViewModel extends ChangeNotifier {
  final AtleticaRemoteDatasource _ds = AtleticaRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _nome = '';
  String _nomePresidente = '';
  Color _corPrimaria = const Color(0xFF2563EB);
  Color _corFundo = const Color(0xFFF8FAFC);
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _atleticaId;

  String get nome => _nome;
  String get nomePresidente => _nomePresidente;
  Color get corPrimaria => _corPrimaria;
  Color get corFundo => _corFundo;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _atleticaId = await _tokenDs.getAtleticaId();
      if (_atleticaId == null) return;
      final data = await _ds.getAtletica(_atleticaId!);
      _nome           = data['nome'] as String? ?? '';
      _nomePresidente = data['nomePresidente'] as String? ?? '';
      final corPrimariaHex = data['corPrimaria'] as String?;
      final corFundoHex    = data['corFundo'] as String?;
      if (corPrimariaHex != null) _corPrimaria = _hexToColor(corPrimariaHex);
      if (corFundoHex != null)    _corFundo    = _hexToColor(corFundoHex);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCorPrimaria(Color c) {
    _corPrimaria = c;
    notifyListeners();
  }

  void setCorFundo(Color c) {
    _corFundo = c;
    notifyListeners();
  }

  Future<bool> save({required String nome, required String nomePresidente}) async {
    if (nome.isEmpty || nomePresidente.isEmpty) {
      _error = 'Preencha todos os campos.';
      notifyListeners();
      return false;
    }
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _ds.updateAtletica(_atleticaId!, {
        'nome':           nome,
        'nomePresidente': nomePresidente,
        'corPrimaria':    _colorToHex(_corPrimaria),
        'corFundo':       _colorToHex(_corFundo),
      });
      _nome           = nome;
      _nomePresidente = nomePresidente;
      return true;
    } catch (_) {
      _error = 'Erro ao salvar. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
}