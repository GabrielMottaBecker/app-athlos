import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

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

  void addPost(PostModel p) {
    _repo.addPost(p);
    _posts = _repo.getPosts();
    notifyListeners();
  }

  void updatePost(PostModel p) {
    _repo.updatePost(p);
    _posts = _repo.getPosts();
    notifyListeners();
  }

  void removePost(String id) {
    _repo.removePost(id);
    _posts = _repo.getPosts();
    notifyListeners();
  }

  void refresh() {
    _posts = _repo.getPosts();
    notifyListeners();
  }
}

class RegisterPostViewModel extends ChangeNotifier {
  final FeedRepository _repo = FeedRepository();
  final _picker = ImagePicker();
  final PostModel? initialPost;

  String _selectedCategory = 'PRESIDÊNCIA';
  bool _isLoading = false;
  XFile? _image;

  static const List<String> categories = ['PRESIDÊNCIA', 'TREINO', 'COMPETIÇÃO', 'AVISO'];
  static const Map<String, int> categoryColors = {
    'PRESIDÊNCIA': 0xFF2563EB,
    'TREINO': 0xFF10B981,
    'COMPETIÇÃO': 0xFFF59E0B,
    'AVISO': 0xFFEF4444,
  };

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isEditMode => initialPost != null;
  XFile? get selectedImage => _image;

  RegisterPostViewModel({this.initialPost}) {
    if (initialPost != null) {
      _selectedCategory = initialPost!.category;
      if (initialPost!.imagePath != null) {
        _image = XFile(initialPost!.imagePath!);
      }
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
    await Future.delayed(const Duration(milliseconds: 300));

    if (isEditMode) {
      _repo.updatePost(initialPost!.copyWith(
        title: title.trim(),
        category: _selectedCategory,
        categoryColor: categoryColors[_selectedCategory],
        hasImage: _image != null,
        imagePath: _image?.path,
      ));
    } else {
      _repo.addPost(PostModel(
        id: _repo.nextId,
        category: _selectedCategory,
        categoryColor: categoryColors[_selectedCategory]!,
        title: title.trim(),
        timeAgo: 'agora',
        likes: 0,
        comments: 0,
        hasImage: _image != null,
        imagePath: _image?.path,
      ));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
