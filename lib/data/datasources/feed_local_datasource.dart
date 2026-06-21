import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persistência local do Feed.
///
/// Guarda a última lista de posts obtida da API, por atlética, para que
/// o usuário consiga ver conteúdo imediatamente ao reabrir o app — mesmo
/// antes (ou na ausência) de resposta da API — e o app continue
/// funcional offline / com falha de conexão.
class FeedLocalDatasource {
  static const _keyPrefix = 'feed_posts_cache_';
  static const _timestampSuffix = '_timestamp';

  /// Salva a lista de posts retornada pela API para a atlética informada.
  Future<void> savePosts(String atleticaId, List<PostModel> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(posts.map((p) => p.toJson()).toList());
    await prefs.setString(_key(atleticaId), encoded);
    await prefs.setString(
      _key(atleticaId) + _timestampSuffix,
      DateTime.now().toIso8601String(),
    );
  }

  /// Recupera os posts persistidos localmente, se existirem.
  /// Retorna lista vazia caso não haja cache para essa atlética.
  Future<List<PostModel>> getPosts(String atleticaId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(atleticaId));
    if (raw == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => PostModel.fromCacheJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Cache corrompido / formato antigo: ignora e segue sem cache.
      return [];
    }
  }

  /// Data/hora da última sincronização bem-sucedida com a API.
  Future<DateTime?> getLastSyncedAt(String atleticaId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(atleticaId) + _timestampSuffix);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clear(String atleticaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(atleticaId));
    await prefs.remove(_key(atleticaId) + _timestampSuffix);
  }

  String _key(String atleticaId) => '$_keyPrefix$atleticaId';
}
