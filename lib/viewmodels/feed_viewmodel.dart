import 'package:flutter/material.dart';
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

  void removePost(String id) {
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
