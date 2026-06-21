import 'package:flutter/material.dart';
import '../data/datasources/notificacoes_remote_datasource.dart';

class NotificacoesViewModel extends ChangeNotifier {
  final NotificacoesRemoteDatasource _ds = NotificacoesRemoteDatasource();

  List<Map<String, dynamic>> _notificacoes = [];
  int _naoLidas = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notificacoes => _notificacoes;
  int get naoLidas => _naoLidas;
  bool get isLoading => _isLoading;

  NotificacoesViewModel();

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notificacoes = await _ds.getNotificacoes();
      _naoLidas     = await _ds.getCountNaoLidas();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarComoLida(String id) async {
    try {
      await _ds.marcarComoLida(id);
      final idx = _notificacoes.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        _notificacoes[idx] = {..._notificacoes[idx], 'lida': true};
        if (_naoLidas > 0) _naoLidas--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> marcarTodasComoLidas() async {
    try {
      await _ds.marcarTodasComoLidas();
      _notificacoes = _notificacoes.map((n) => {...n, 'lida': true}).toList();
      _naoLidas = 0;
      notifyListeners();
    } catch (_) {}
  }
}