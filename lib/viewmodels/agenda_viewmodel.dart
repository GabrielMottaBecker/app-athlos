import 'package:flutter/material.dart';
import '../data/datasources/feed_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';

// ─── Agenda (usuário) ─────────────────────────────────────────────────────────
class AgendaViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _activeFilter = 'Todo';
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;

  String get activeFilter => _activeFilter;
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const List<String> filters = ['Todo', 'Treinos', 'Eventos', 'Extras'];

  static const _filterMap = {
    'Treinos': 'TREINO',
    'Eventos': 'EVENTO',
    'Extras':  'EXTRA',
  };

  AgendaViewModel();

  Future<void> load() async {
    // Aguarda o token estar disponível (máx 3s)
    String? atleticaId;
    for (int i = 0; i < 6; i++) {
      atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (atleticaId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final type = _filterMap[_activeFilter];
      _events = await _ds.getEvents(atleticaId, type: type);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    load();
  }

  Future<void> confirmPresence(String eventId) async {
    try {
      await _ds.confirmarPresenca(eventId);
    } catch (_) {}
    notifyListeners();
  }
}

// ─── Agenda Admin ─────────────────────────────────────────────────────────────
class AdminAgendaViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  List<EventModel> _events = [];
  bool _isLoading = false;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  int get totalCount => _events.length;
  int get treinoCount => _events.where((e) => e.type == 'TREINO').length;

  AdminAgendaViewModel() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _events = await _ds.getEvents(atleticaId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeEvent(String id) async {
    await _ds.deleteEvento(id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> refresh() => load();
}

// ─── Cadastrar / Editar Evento ────────────────────────────────────────────────
class RegisterEventViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final EventModel? initialEvent;

  late String _selectedType;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isEditMode => initialEvent != null;
  String get selectedType => _selectedType;

  static const List<String> types = ['TREINO', 'EVENTO SOCIAL', 'EXTRAS', 'COMPETICAO'];

  static const Map<String, int> _typeColors = {
    'TREINO':        0xFF10B981,
    'EVENTO SOCIAL': 0xFFF59E0B,
    'EXTRAS':        0xFF8B5CF6,
    'COMPETICAO':    0xFFEF4444,
  };
  static const Map<String, int> _bgColors = {
    'TREINO':        0xFF1E3A5F,
    'EVENTO SOCIAL': 0xFF3A1E5F,
    'EXTRAS':        0xFF2E1E5F,
    'COMPETICAO':    0xFF5F1E1E,
  };

  RegisterEventViewModel({this.initialEvent}) {
    _selectedType = initialEvent?.type ?? 'TREINO';
  }

  void setType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  Future<bool> save({
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    required String place,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final timeStr = [startTime.trim(), endTime.trim()]
          .where((t) => t.isNotEmpty)
          .join(' – ');

      if (isEditMode) {
        // UpdateEventoDto não aceita atleticaId
        final body = {
          'title':     title.trim().toUpperCase(),
          'date':      date.trim().toUpperCase(),
          'type':      _selectedType,
          'typeColor': _typeColors[_selectedType],
          'time':      timeStr,
          'place':     place.trim(),
          'bgColor':   _bgColors[_selectedType],
        };
        await _ds.updateEvento(initialEvent!.id, body);
      } else {
        final atleticaId = await _tokenDs.getAtleticaId();
        final body = {
          'title':      title.trim().toUpperCase(),
          'date':       date.trim().toUpperCase(),
          'type':       _selectedType,
          'typeColor':  _typeColors[_selectedType],
          'time':       timeStr,
          'place':      place.trim(),
          'bgColor':    _bgColors[_selectedType],
          'atleticaId': atleticaId,
        };
        await _ds.createEvento(body);
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('>>> ERRO save evento: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}