import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class ParticipantesViewModel extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository();

  String _searchQuery = '';
  List<MemberModel> _members = [];

  String get searchQuery => _searchQuery;
  List<MemberModel> get members {
    if (_searchQuery.isEmpty) return _members;
    return _members
        .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  ParticipantesViewModel() {
    _members = _repo.getUserMembers();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

class AdminMembersViewModel extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository();

  String _searchQuery = '';
  String _statusFilter = 'Todos';

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<MemberModel> get members {
    var list = _repo.getAdminMembers();
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_statusFilter == 'Ativos') {
      list = list.where((m) => m.status == 'ATIVO').toList();
    } else if (_statusFilter == 'Inativos') {
      list = list.where((m) => m.status == 'INATIVO').toList();
    }
    return list;
  }

  static const List<String> statusFilters = ['Todos', 'Ativos', 'Inativos'];

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void removeMember(String id) {
    _repo.removeMember(id);
    notifyListeners();
  }

  void updateMember(MemberModel updated) {
    _repo.updateMember(updated);
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

class RegisterMemberViewModel extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository();
  final MemberModel? initialMember;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isLoading = false;

  String get selectedRole => _selectedRole;
  String get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  bool get isEditMode => initialMember != null;

  static const List<String> roles = [
    'Membro', 'Diretor', 'Coordenador', 'Financeiro', 'Marketing', 'Vice-Presidente',
  ];
  static const List<String> statuses = ['ATIVO', 'INATIVO'];

  RegisterMemberViewModel({this.initialMember}) {
    final role = initialMember?.role ?? 'Membro';
    _selectedRole = roles.contains(role)
        ? role
        : roles.firstWhere(
            (r) => r.toUpperCase() == role.toUpperCase(),
            orElse: () => 'Membro',
          );
    _selectedStatus = initialMember?.status ?? 'ATIVO';
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
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    if (isEditMode) {
      _repo.updateMember(initialMember!.copyWith(
        name: name.trim().isEmpty ? null : name.trim(),
        role: _selectedRole.toUpperCase(),
        status: _selectedStatus,
        email: email.trim(),
        ra: ra.trim(),
        curso: curso.trim(),
      ));
    } else {
      _repo.addMember(MemberModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rank: _repo.nextRank,
        name: name.trim(),
        role: _selectedRole.toUpperCase(),
        status: _selectedStatus,
        email: email.trim(),
        ra: ra.trim(),
        curso: curso.trim(),
      ));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
