import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/datasources/members_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';

// ─── Participantes (usuário) ──────────────────────────────────────────────────
class ParticipantesViewModel extends ChangeNotifier {
  final MembersRemoteDatasource _ds = MembersRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _searchQuery = '';
  List<MemberModel> _members = [];
  bool _isLoading = false;

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<MemberModel> get members {
    if (_searchQuery.isEmpty) return _members;
    return _members
        .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  ParticipantesViewModel();

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _members = await _ds.getAssociados(atleticaId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

// ─── Admin Members ────────────────────────────────────────────────────────────
class AdminMembersViewModel extends ChangeNotifier {
  final MembersRemoteDatasource _ds = MembersRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _searchQuery = '';
  String _statusFilter = 'Todos';
  List<MemberModel> _members = [];
  bool _isLoading = false;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;

  static const List<String> statusFilters = ['Todos', 'Ativos', 'Inativos'];

  List<MemberModel> get members {
    var list = _members;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_statusFilter == 'Ativos') {
      list = list.where((m) => m.status == 'ATIVO').toList();
    } else if (_statusFilter == 'Inativos') {
      list = list.where((m) => m.status == 'INATIVO').toList();
    }
    return list;
  }

  AdminMembersViewModel() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _members = await _ds.getAssociados(atleticaId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  Future<void> inativarMember(String id) async {
    await _ds.changeStatus(id, 'INATIVO');
    final idx = _members.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _members[idx] = _members[idx].copyWith(status: 'INATIVO');
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}

// ─── Cadastrar / Editar Membro ────────────────────────────────────────────────
class RegisterMemberViewModel extends ChangeNotifier {
  final MembersRemoteDatasource _ds = MembersRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final MemberModel? initialMember;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _cargos = [];

  String get selectedRole => _selectedRole;
  String get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditMode => initialMember != null;
  List<Map<String, dynamic>> get cargos => _cargos;

  static const List<String> roles = [
  'Membro', 'Diretor', 'Coordenador', 'Financeiro',
  'Marketing', 'Vice-Presidente', 'Presidente',
];

  static const List<String> statuses = ['ATIVO', 'INATIVO'];

  RegisterMemberViewModel({this.initialMember}) {
    _selectedRole   = initialMember?.role ?? '';
    _selectedStatus = initialMember?.status ?? 'ATIVO';
    _loadCargos();
  }

  Future<void> _loadCargos() async {
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _cargos = await _ds.getCargos(atleticaId);
      if (_selectedRole.isEmpty && _cargos.isNotEmpty) {
        _selectedRole = _cargos.first['nome'] as String;
      }
      notifyListeners();
    } catch (_) {}
  }

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<bool> save({
    required String name,
    required String email,
    required String ra,
    required String curso,
    required String senha,
    required String telefone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cargo = _cargos.firstWhere(
        (c) => c['nome'] == _selectedRole,
        orElse: () => {},
      );
      final cargoId = cargo['id'] as String?;

      if (isEditMode) {
        // UpdateAssociadoDto só aceita nome, email, documento, telefone
        final body = {
          'nome':      name.trim(),
          'email':     email.trim(),
          'documento': ra.trim(),
          'telefone':  telefone.trim(),
        };
        await _ds.updateAssociado(initialMember!.id, body);
        // Cargo é atualizado em endpoint separado (PATCH /associados/:id/cargo)
        await _ds.assignCargo(initialMember!.id, cargoId);
      } else {
        final atleticaId = await _tokenDs.getAtleticaId();
        final body = {
          'nome':            name.trim(),
          'email':           email.trim(),
          'documento':       ra.trim(),
          'telefone':        telefone.trim(),
          'atleticaId':      atleticaId,
          'valorAssociacao': 0,
          if (cargoId != null) 'cargoId': cargoId,
        };
        await _ds.createAssociado(body);
      }
      return true;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String) {
            _error = _translateError(msg);
          } else if (msg is List && msg.isNotEmpty) {
            _error = _translateError(msg.first.toString());
          }
        }
        _error ??= 'Erro ao salvar membro. Tente novamente.';
      } else {
        _error = 'Erro inesperado ao salvar membro.';
      }
      // ignore: avoid_print
      print('>>> ERRO save membro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _translateError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('documento') || lower.contains('cpf') || lower.contains('ra')) {
      return 'Registro Acadêmico já registrado em outro usuário.';
    }
    if (lower.contains('e-mail') || lower.contains('email')) {
      return 'E-mail já cadastrado em outro usuário.';
    }
    return raw;
  }
}