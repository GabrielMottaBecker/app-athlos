import 'package:flutter/material.dart';
import '../data/datasources/feed_remote_datasource.dart';
import '../data/datasources/members_remote_datasource.dart';
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
  final Set<String> _pendingPresenceIds = {};

  String get activeFilter => _activeFilter;
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isPresenceLoading(String eventId) => _pendingPresenceIds.contains(eventId);

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
      final fetched = await _ds.getEvents(atleticaId, type: type);
      // Avisos vivem na mesma rota de eventos, mas não têm agenda
      // (sem data/hora/local) — não devem aparecer aqui, só no Feed.
      _events = fetched.where((e) => e.type != 'AVISO').toList();
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

  /// Confirma ou cancela a presença do usuário no evento/treino, dependendo
  /// do estado atual (`EventModel.confirmado`). Retorna uma mensagem de erro
  /// amigável em caso de falha, ou `null` em caso de sucesso.
  Future<String?> togglePresence(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1 || _pendingPresenceIds.contains(eventId)) return null;

    final original = _events[index];
    final willConfirm = !original.confirmado;

    // Atualização otimista: já reflete o novo estado na UI.
    _pendingPresenceIds.add(eventId);
    _events[index] = original.copyWith(confirmado: willConfirm);
    notifyListeners();

    try {
      if (willConfirm) {
        await _ds.confirmarPresenca(eventId);
      } else {
        final usuarioId = await _tokenDs.getUserId();
        if (usuarioId == null) throw Exception('Sessão inválida');
        await _ds.removerPresenca(eventId, usuarioId);
      }
      return null;
    } catch (e) {
      // Reverte em caso de erro real (token expirado, sem conexão, etc).
      // A confirmação em si é idempotente no backend, então erros aqui
      // já não incluem mais o "Presença já confirmada" (409).
      _events[index] = original;
      return willConfirm
          ? 'Não foi possível confirmar sua presença. Tente novamente.'
          : 'Não foi possível cancelar sua presença. Tente novamente.';
    } finally {
      _pendingPresenceIds.remove(eventId);
      notifyListeners();
    }
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

// ─── Presença de um Evento (admin) ────────────────────────────────────────────
/// Item já resolvido (e-mail cruzado com o cadastro de associados) para
/// exibição na tela administrativa de presença.
class PresenceListItem {
  final String usuarioId;
  final String email;
  final String name; // nome do associado, ou o próprio email se não encontrado
  final DateTime? confirmadoEm;

  const PresenceListItem({
    required this.usuarioId,
    required this.email,
    required this.name,
    this.confirmadoEm,
  });
}

class EventPresenceViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _feedDs = FeedRemoteDatasource();
  final MembersRemoteDatasource _membersDs = MembersRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  final EventModel event;
  EventPresenceViewModel(this.event);

  List<PresenceListItem> _confirmados = [];
  bool _isLoading = false;
  String? _error;

  List<PresenceListItem> get confirmados => _confirmados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalConfirmados => _confirmados.length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();

      // Busca em paralelo: presenças do evento + associados da atlética
      // (para resolver nome a partir do e-mail).
      final results = await Future.wait([
        _feedDs.getPresencas(event.id),
        if (atleticaId != null) _membersDs.getAssociados(atleticaId),
      ]);

      final presencas = results[0] as List<EventPresenceModel>;
      final membros = atleticaId != null
          ? results[1] as List<MemberModel>
          : <MemberModel>[];

      final byEmail = {for (final m in membros) m.email.toLowerCase(): m};

      _confirmados = presencas.map((p) {
        final membro = byEmail[p.email.toLowerCase()];
        return PresenceListItem(
          usuarioId: p.usuarioId,
          email: p.email,
          name: membro?.name ?? p.email,
          confirmadoEm: p.confirmadoEm,
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      _error = 'Não foi possível carregar a lista de presença.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
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