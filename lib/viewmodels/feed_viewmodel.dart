import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/datasources/feed_remote_datasource.dart';
import '../data/datasources/feed_local_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';

// ─── Feed (usuário) ───────────────────────────────────────────────────────────
class FeedViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final FeedLocalDatasource _localDs = FeedLocalDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _activeFilter = 'RECENTES';
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  bool _isFromCache = false;
  DateTime? _lastSyncedAt;

  String get activeFilter => _activeFilter;
  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// true quando os dados exibidos vieram do cache local (offline / falha de API)
  bool get isFromCache => _isFromCache;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  static const List<String> filters = ['RECENTES', 'PRESIDÊNCIA', 'ESPORTES'];

  FeedViewModel() {
    //load();
  }

  Future<void> load() async {
    String? atleticaId;
    for (int i = 0; i < 6; i++) {
      atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (atleticaId == null) return; // sem token, não carrega

    // 1) Mostra o que já existe em cache imediatamente (recuperação ao reabrir o app)
    final cached = await _localDs.getPosts(atleticaId);
    if (cached.isNotEmpty) {
      _posts = cached;
      _isFromCache = true;
      _lastSyncedAt = await _localDs.getLastSyncedAt(atleticaId);
      notifyListeners();
    }

    // 2) Sincroniza com a API
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await _ds.getPosts(atleticaId);
      _posts = fresh;
      _isFromCache = false;
      _lastSyncedAt = DateTime.now();
      // Persiste localmente para a próxima vez que o app for aberto
      await _localDs.savePosts(atleticaId, fresh);
    } catch (e) {
      // Falha de conexão/timeout/erro: mantém o que estava em cache (se houver)
      // e só expõe erro se não há nada para mostrar.
      _error = e.toString();
      _isFromCache = _posts.isNotEmpty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  List<PostModel> get filteredPosts {
    if (_activeFilter == 'RECENTES') return _posts;
    final map = {'PRESIDÊNCIA': 'PRESIDÊNCIA', 'ESPORTES': 'TREINO'};
    final cat = map[_activeFilter] ?? _activeFilter;
    return _posts.where((p) => p.category == cat).toList();
  }
}

// ─── Feed Admin ───────────────────────────────────────────────────────────────
class AdminFeedViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _searchQuery = '';
  List<PostModel> _posts = [];
  bool _isLoading = false;

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<PostModel> get posts {
    if (_searchQuery.isEmpty) return _posts;
    return _posts
        .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  AdminFeedViewModel() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      print('>>> atleticaId do storage: $atleticaId');
      if (atleticaId == null) throw Exception('Atlética não identificada');
      _posts = await _ds.getPosts(atleticaId);
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

  Future<void> removePost(String id) async {
    await _ds.deleteEvento(id);
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> refresh() => load();
}

// ─── Cadastrar / Editar Post ──────────────────────────────────────────────────
class RegisterPostViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final _picker = ImagePicker();
  final PostModel? initialPost;

  String _selectedCategory = 'PRESIDÊNCIA';
  bool _isLoading = false;
  XFile? _image;

  static const List<String> categories = ['PRESIDÊNCIA', 'TREINO', 'COMPETIÇÃO', 'AVISO'];
  static const Map<String, int> categoryColors = {
    'PRESIDÊNCIA': 0xFF2563EB,
    'TREINO':      0xFF10B981,
    'COMPETIÇÃO':  0xFFF59E0B,
    'AVISO':       0xFFEF4444,
  };

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isEditMode => initialPost != null;
  XFile? get selectedImage => _image;

  RegisterPostViewModel({this.initialPost}) {
    if (initialPost != null) {
      _selectedCategory = initialPost!.category;
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final img = await _picker.pickImage(source: source, imageQuality: 80);
    if (img != null) {
      _image = img;
      notifyListeners();
    }
  }

  void removeImage() {
    _image = null;
    notifyListeners();
  }

  Future<bool> save({required String title}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      final body = {
        'title': title.trim(),
        'type': _selectedCategory,
        'atleticaId': atleticaId,
      };
      if (isEditMode) {
        await _ds.updateEvento(initialPost!.id, body);
      } else {
        await _ds.createEvento(body);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}