import '../../core/network/dio_client.dart';
import '../models/models.dart';

class MembersRemoteDatasource {
  Future<List<MemberModel>> getAssociados(String atleticaId) async {
    final response = await DioClient.associacao
        .get('/associados/atletica/$atleticaId');
    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;
    return items
        .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> createAssociado(Map<String, dynamic> body) async {
    final response = await DioClient.associacao.post('/associados', data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['id'] as String?;
    }
    return null;
  }

  Future<void> updateAssociado(String id, Map<String, dynamic> body) async {
    await DioClient.associacao.put('/associados/$id', data: body);
  }

  Future<void> assignCargo(String id, String? cargoId) async {
    await DioClient.associacao
        .patch('/associados/$id/cargo', data: {'cargoId': cargoId});
  }

  Future<void> changeStatus(String id, String status) async {
    await DioClient.associacao
        .patch('/associados/$id/status', data: {'status': status});
  }

  Future<List<Map<String, dynamic>>> getCargos(String atleticaId) async {
    final response = await DioClient.associacao
        .get('/cargos/atletica/$atleticaId');
    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;
    return items.cast<Map<String, dynamic>>();
  }
}