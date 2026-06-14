import '../../core/network/dio_client.dart';
import '../models/models.dart';

class LojaRemoteDatasource {
  Future<List<ProductModel>> getProdutos(String atleticaId) async {
    final response = await DioClient.lojinha
        .get('/produtos/atletica/$atleticaId');
    final List<dynamic> items = response.data is List
        ? response.data as List
        : (response.data['data'] ?? response.data['items'] ?? []) as List;
    return items
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> createProduto(Map<String, dynamic> body) async {
    final response = await DioClient.lojinha.post('/produtos', data: body);
    return response.data['id'] as String?;
  }

  Future<void> updateProduto(String id, Map<String, dynamic> body) async {
    await DioClient.lojinha.put('/produtos/$id', data: body);
  }

  Future<void> changeStatus(String id, String status) async {
    await DioClient.lojinha
        .patch('/produtos/$id/status', data: {'status': status});
  }

  Future<String> gerarLinkWhatsapp(List<Map<String, dynamic>> itens) async {
    final response = await DioClient.lojinha.post(
      '/carrinho/whatsapp',
      data: {'itens': itens},
    );
    return response.data['url'] as String? ?? '';
  }
}