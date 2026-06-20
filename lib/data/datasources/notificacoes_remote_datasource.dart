import '../../core/network/dio_client.dart';

class NotificacoesRemoteDatasource {
  Future<List<Map<String, dynamic>>> getNotificacoes() async {
    final response = await DioClient.notificacoes.get('/notificacoes');
    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;
    return items.cast<Map<String, dynamic>>();
  }

  Future<int> getCountNaoLidas() async {
    final response = await DioClient.notificacoes.get('/notificacoes/nao-lidas/count');
    return response.data['count'] as int? ?? 0;
  }

  Future<void> marcarComoLida(String id) async {
    await DioClient.notificacoes.patch('/notificacoes/$id/lida');
  }

  Future<void> marcarTodasComoLidas() async {
    await DioClient.notificacoes.patch('/notificacoes/lidas');
  }
}