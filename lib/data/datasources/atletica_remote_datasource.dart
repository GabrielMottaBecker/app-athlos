import '../../core/network/dio_client.dart';

class AtleticaRemoteDatasource {
  Future<Map<String, dynamic>> createAtletica({
    required String nome,
    required String nomePresidente,
    required String corPrimaria,
    required String corFundo,
  }) async {
    final response = await DioClient.identidade.post('/atleticas', data: {
      'nome':           nome,
      'nomePresidente': nomePresidente,
      'corPrimaria':    corPrimaria,
      'corFundo':       corFundo,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAtletica(String id) async {
    final response = await DioClient.identidade.get('/atleticas/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateAtletica(String id, Map<String, dynamic> body) async {
    await DioClient.identidade.patch('/atleticas/$id', data: body);
  }

  Future<void> changeStatus(String id, String status) async {
    await DioClient.identidade.patch('/atleticas/$id/status', data: {'status': status});
  }

  Future<void> deleteAtletica(String id) async {
    await DioClient.identidade.delete('/atleticas/$id');
  }
}
