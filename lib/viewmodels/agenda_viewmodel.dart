import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class AgendaViewModel extends ChangeNotifier {
  final EventRepository _repo = EventRepository();

  String _activeFilter = 'Todo';
  List<EventModel> _events = [];

  String get activeFilter => _activeFilter;
  List<EventModel> get events => _events;

  static const List<String> filters = ['Todo', 'Treinos', 'Eventos', 'Extras'];

  AgendaViewModel() {
    _loadEvents();
  }

  void _loadEvents() {
    _events = _repo.getEvents(filter: _activeFilter);
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    _loadEvents();
  }

  void confirmPresence(String eventId) {
    notifyListeners();
  }
}

class AdminAgendaViewModel extends ChangeNotifier {
  final EventRepository _repo = EventRepository();

  List<EventModel> get events => _repo.getEvents();
  int get totalCount => events.length;
  int get treinoCount => events.where((e) => e.type == 'TREINO').length;

  void removeEvent(String id) {
    _repo.removeEvent(id);
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

class RegisterEventViewModel extends ChangeNotifier {
  final EventRepository _repo = EventRepository();
  final EventModel? initialEvent;

  late String _selectedType;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isEditMode => initialEvent != null;
  String get selectedType => _selectedType;

  static const List<String> types = ['TREINO', 'EVENTO SOCIAL', 'EXTRAS'];

  static const Map<String, int> _typeColors = {
    'TREINO': 0xFF10B981,
    'EVENTO SOCIAL': 0xFFF59E0B,
    'EXTRAS': 0xFF8B5CF6,
  };
  static const Map<String, int> _bgColors = {
    'TREINO': 0xFF1E3A5F,
    'EVENTO SOCIAL': 0xFF3A1E5F,
    'EXTRAS': 0xFF2E1E5F,
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
    await Future.delayed(const Duration(milliseconds: 300));

    final timeStr = startTime.trim().isNotEmpty && endTime.trim().isNotEmpty
        ? '${startTime.trim()} – ${endTime.trim()}'
        : startTime.trim().isNotEmpty
            ? startTime.trim()
            : endTime.trim();

    final event = EventModel(
      id: isEditMode ? initialEvent!.id : _repo.nextId,
      date: date.trim().toUpperCase(),
      type: _selectedType,
      typeColor: _typeColors[_selectedType] ?? 0xFF10B981,
      title: title.trim().toUpperCase(),
      time: timeStr,
      place: place.trim(),
      bgColor: _bgColors[_selectedType] ?? 0xFF1E3A5F,
    );

    isEditMode ? _repo.updateEvent(event) : _repo.addEvent(event);

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
