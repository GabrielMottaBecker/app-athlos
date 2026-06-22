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

  /// Curtir/descurtir uma publicação. Estado puramente local — não é
  /// enviado ao backend e reseta ao recarregar o Feed.
  void toggleLike(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    final liked = !post.likedByMe;
    _posts[index] = post.copyWith(
      likedByMe: liked,
      likes: liked ? post.likes + 1 : (post.likes > 0 ? post.likes - 1 : 0),
    );
    notifyListeners();
  }

  /// Adiciona um comentário local a uma publicação. Não é enviado ao
  /// backend — vive só em memória durante a sessão atual.
  void addComment(String postId, String authorName, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    final newComment = CommentModel(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      authorName: authorName,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    _posts[index] = post.copyWith(
      commentsList: [...post.commentsList, newComment],
      comments: post.comments + 1,
    );
    notifyListeners();
  }
}

// ─── Feed Admin ───────────────────────────────────────────────────────────────
/// Item unificado do Feed administrativo: pode representar um Aviso (post)
/// ou um Treino/Evento, já que ambos vivem na mesma entidade `/eventos`
/// no backend. A UI deixou de ter uma aba "Agenda" separada — treinos,
/// eventos e avisos agora aparecem juntos aqui.
class AdminFeedItem {
  final PostModel post;
  final EventModel event;
  /// true quando o item tem informações de agenda (data/hora/local),
  /// ou seja, é um Treino/Evento e não um Aviso simples.
  final bool isEvento;

  const AdminFeedItem({required this.post, required this.event, required this.isEvento});

  String get id => post.id;
  String get title => post.title;
}

class AdminFeedViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _searchQuery = '';
  List<AdminFeedItem> _items = [];
  bool _isLoading = false;

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<AdminFeedItem> get items {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) => i.title.toLowerCase().contains(q)).toList();
  }

  AdminFeedViewModel() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) throw Exception('Atlética não identificada');

      // Posts e Eventos vêm da mesma rota (/eventos/atletica/:id) no backend;
      // aqui buscamos os dois parses para saber exibir cada item corretamente
      // (treino/evento tem data/hora/local; aviso simples não).
      final results = await Future.wait([
        _ds.getPosts(atleticaId),
        _ds.getEvents(atleticaId),
      ]);
      final posts = results[0] as List<PostModel>;
      final events = results[1] as List<EventModel>;
      final eventsById = {for (final e in events) e.id: e};

      _items = posts.map((p) {
        final ev = eventsById[p.id];
        // Avisos são identificados pelo próprio tipo — mais confiável do
        // que checar se date/time/place estão vazios, já que o backend
        // exige esses campos não-vazios mesmo para avisos (usamos '-').
        final isAviso = p.category == 'AVISO';
        return AdminFeedItem(
          post: p,
          event: ev ?? EventModel(id: p.id, date: '', type: p.category, typeColor: p.categoryColor, title: p.title, time: '', place: '', bgColor: p.categoryColor),
          isEvento: !isAviso,
        );
      }).toList();
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

  Future<void> removeItem(String id) async {
    await _ds.deleteEvento(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> refresh() => load();
}

// ─── Cadastrar / Editar Post (Aviso) ──────────────────────────────────────────
class RegisterPostViewModel extends ChangeNotifier {
  final FeedRemoteDatasource _ds = FeedRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final _picker = ImagePicker();
  final PostModel? initialPost;

  /// Todo post criado por aqui é sempre um Aviso — não há mais seleção de
  /// categoria nesta tela.
  static const String category = 'AVISO';
  static const int categoryColor = 0xFFEF4444;

  bool _isLoading = false;
  XFile? _image;

  bool get isLoading => _isLoading;
  bool get isEditMode => initialPost != null;
  XFile? get selectedImage => _image;

  RegisterPostViewModel({this.initialPost});

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
        'type': category,
        'typeColor': categoryColor,
        // Avisos não têm agenda, mas o backend exige date/time/place
        // não-vazios (@IsNotEmpty rejeita string vazia, não só nulo).
        // Mandamos um placeholder fixo só para satisfazer a validação.
        'date': '-',
        'time': '-',
        'place': '-',
        'bgColor': categoryColor,
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