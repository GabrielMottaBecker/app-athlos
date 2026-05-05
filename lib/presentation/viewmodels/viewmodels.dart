import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../core/theme/theme_notifier.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/errors/failures.dart';

enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;

  // Cria o repositório internamente se não for injetado
  AuthViewModel({LoginUseCase? loginUseCase})
      : _loginUseCase = loginUseCase ?? LoginUseCase(AuthRepositoryImpl());

  AuthState state       = AuthState.idle;
  String?   errorMessage;
  String?   role;
  bool      obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      errorMessage = 'Preencha todos os campos';
      state = AuthState.error;
      notifyListeners();
      return;
    }

    state = AuthState.loading;
    errorMessage = null;
    notifyListeners();

    final (AuthEntity? auth, Failure? failure) =
        await _loginUseCase(email, password);

    if (failure != null) {
      state = AuthState.error;
      errorMessage = failure.message;
    } else {
      role  = auth!.role;
      state = AuthState.success;
    }
    notifyListeners();
  }
}

// ─── Feed ViewModel ───────────────────────────────────────────────────────────
class FeedViewModel extends ChangeNotifier {
  final FeedRepository _repo = FeedRepository();

  String _activeFilter = 'RECENTES';
  List<PostModel> _posts = [];

  String get activeFilter => _activeFilter;
  List<PostModel> get posts => _posts;

  static const List<String> filters = ['RECENTES', 'PRESIDÊNCIA', 'ESPORTES'];

  FeedViewModel() {
    _loadPosts();
  }

  void _loadPosts() {
    _posts = _repo.getPosts(filter: _activeFilter);
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    _loadPosts();
  }
}

// ─── Loja ViewModel ───────────────────────────────────────────────────────────
class LojaViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  String _activeCategory = 'All Items';
  List<ProductModel> _products = [];

  String get activeCategory => _activeCategory;
  List<ProductModel> get products => _products;
  double get totalRevenue => _repo.totalRevenue;
  int get totalSales => _repo.totalSales;

  static const List<String> categories = ['All Items', 'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'];

  LojaViewModel() {
    _loadProducts();
  }

  void _loadProducts() {
    _products = _repo.getProducts(category: _activeCategory);
    notifyListeners();
  }

  void setCategory(String category) {
    _activeCategory = category;
    _loadProducts();
  }
}

// ─── Agenda ViewModel ─────────────────────────────────────────────────────────
class AgendaViewModel extends ChangeNotifier {
  final EventRepository _repo = EventRepository();

  String _activeFilter = 'Todo';
  List<EventModel> _events = [];

  String get activeFilter => _activeFilter;
  List<EventModel> get events => _events;

  static const List<String> filters = ['Todo', 'Treinos', 'Eventos', 'Competições'];

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
    // Business logic for confirming presence
    notifyListeners();
  }
}

// ─── Participantes ViewModel ──────────────────────────────────────────────────
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

// ─── Admin Members ViewModel ──────────────────────────────────────────────────
class AdminMembersViewModel extends ChangeNotifier {
  final MemberRepository _repo = MemberRepository();

  String _searchQuery = '';
  String _statusFilter = 'Todos';
  List<MemberModel> _members = [];

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

// ─── Admin Agenda ViewModel ───────────────────────────────────────────────────
class AdminAgendaViewModel extends ChangeNotifier {
  final AgendaRepository _repo = AgendaRepository();
  List<AgendaItemModel> _items = [];

  List<AgendaItemModel> get items => _items;
  int get todayCount => 4;
  int get weekCount => 12;

  AdminAgendaViewModel() {
    _items = _repo.getItems();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}

// ─── Admin Feed ViewModel ─────────────────────────────────────────────────────
class AdminFeedViewModel extends ChangeNotifier {
  final FeedRepository _repo = FeedRepository();
  String _searchQuery = '';
  List<PostModel> _posts = [];

  String get searchQuery => _searchQuery;
  List<PostModel> get posts {
    if (_searchQuery.isEmpty) return _posts;
    return _posts
        .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  AdminFeedViewModel() {
    _posts = _repo.getPosts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void removePost(String id) {
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

// ─── Admin Loja ViewModel ─────────────────────────────────────────────────────
class AdminLojaViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();
  String _activeCategory = 'All Products';
  List<ProductModel> _products = [];

  String get activeCategory => _activeCategory;
  List<ProductModel> get products => _products;
  double get totalRevenue => _repo.totalRevenue;
  int get totalSales => _repo.totalSales;

  static const List<String> categories = ['All Products', 'Camisas', 'Hoodies', 'Acessórios'];

  AdminLojaViewModel() {
    _products = _repo.getProducts();
  }

  void setCategory(String cat) {
    _activeCategory = cat;
    _products = cat == 'All Products' ? _repo.getProducts() : _repo.getProducts(category: cat);
    notifyListeners();
  }

  void removeProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

// ─── President Onboarding ViewModel ──────────────────────────────────────────
class PresidentOnboardingViewModel extends ChangeNotifier {
  int _step = 0;
  Color _primaryColor = const Color(0xFF2563EB);
  Color _backgroundColor = const Color(0xFFF8FAFC);
  String _atleticaName = '';
  String _presidentName = '';

  int get step => _step;
  Color get primaryColor => _primaryColor;
  Color get backgroundColor => _backgroundColor;
  String get atleticaName => _atleticaName;
  String get presidentName => _presidentName;

  bool get canGoNext => _step < 1;
  bool get canGoBack => _step > 0;

  void nextStep() {
    if (_step < 1) {
      _step++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_step > 0) {
      _step--;
      notifyListeners();
    }
  }

  void setAtleticaName(String name) {
    _atleticaName = name;
    notifyListeners();
  }

  void setPresidentName(String name) {
    _presidentName = name;
    notifyListeners();
  }

  void setPrimaryColor(Color color, ThemeNotifier themeNotifier) {
    _primaryColor = color;
    themeNotifier.setPrimaryColor(color);
    notifyListeners();
  }

  void setBackgroundColor(Color color, ThemeNotifier themeNotifier) {
    _backgroundColor = color;
    themeNotifier.setBackgroundColor(color);
    notifyListeners();
  }

  AtleticaModel buildAtleticaModel() => AtleticaModel(
    name: _atleticaName,
    presidentName: _presidentName,
    primaryColorValue: _primaryColor.value,
    backgroundColorValue: _backgroundColor.value,
  );
}

// ─── Register / Edit Member ViewModel ────────────────────────────────────────
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
    required String senha,
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
        senha: senha.trim(),
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
        senha: senha.trim(),
      ));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}

