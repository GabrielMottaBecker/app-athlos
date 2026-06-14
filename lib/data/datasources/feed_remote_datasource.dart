import '../../core/network/dio_client.dart';
import '../models/models.dart';

class FeedRemoteDatasource {
  Future<List<PostModel>> getPosts(String atleticaId) async {
    print('>>> Buscando posts para atleticaId: $atleticaId');
    final response = await DioClient.feed.get('/eventos/atletica/$atleticaId');
    print('>>> Resposta: ${response.data}');

    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;

    return items
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EventModel>> getEvents(String atleticaId, {String? type}) async {
    final path = type != null
        ? '/eventos/atletica/$atleticaId/tipo/$type'
        : '/eventos/atletica/$atleticaId';
    final response = await DioClient.feed.get(path);

    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;

    return items
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvento(Map<String, dynamic> body) async {
    await DioClient.feed.post('/eventos', data: body);
  }

  Future<void> updateEvento(String id, Map<String, dynamic> body) async {
    await DioClient.feed.put('/eventos/$id', data: body);
  }

  Future<void> deleteEvento(String id) async {
    await DioClient.feed.delete('/eventos/$id');
  }

  Future<void> confirmarPresenca(String eventoId) async {
    await DioClient.feed.post('/eventos/$eventoId/presencas');
  }
}