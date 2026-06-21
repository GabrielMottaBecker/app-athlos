import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../datasources/token_local_datasource.dart';
import '../../core/network/dio_client.dart';

class AuthRemoteDatasource {
  final TokenLocalDatasource _tokenDatasource;

  AuthRemoteDatasource({TokenLocalDatasource? tokenDatasource})
      : _tokenDatasource = tokenDatasource ?? TokenLocalDatasource();

  Future<AuthModel> login(String email, String password) async {
    try {
      final response = await DioClient.identidade.post(
        '/auth/login',
        data: {'email': email, 'senha': password},
      );

      final auth = AuthModel.fromJson(response.data);

      await _tokenDatasource.saveTokens(
        access: auth.accessToken,
        refresh: auth.refreshToken,
        role: auth.role,
        userId: auth.userId,
        atleticaId: auth.atleticaId,
      );

      return auth;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<void> refreshToken() async {
    final refreshToken = await _tokenDatasource.getRefreshToken();
    if (refreshToken == null) throw Exception('Sem refresh token');

    final response = await DioClient.identidade.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final auth = AuthModel.fromJson(response.data);

    await _tokenDatasource.saveTokens(
      access: auth.accessToken,
      refresh: auth.refreshToken,
      role: auth.role,
      userId: auth.userId,
    );
  }

  Future<void> logout() async {
    final refreshToken = await _tokenDatasource.getRefreshToken();
    try {
      await DioClient.identidade.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // mesmo com erro na API, limpa tokens locais
    } finally {
      await _tokenDatasource.clearTokens();
    }
  }

  /// Primeiro acesso do membro — etapa 1: confirma email + telefone.
  /// Retorna o token de sessão de ativação (válido por 10 minutos) e o
  /// nome do membro, para exibir na tela seguinte.
  Future<({String tokenSessao, String nome})> verificarAssociado({
    required String email,
    required String telefone,
  }) async {
    try {
      final response = await DioClient.identidade.post(
        '/auth/verificar-associado',
        data: {'email': email, 'telefone': telefone},
      );

      return (
        tokenSessao: response.data['tokenSessao'] as String,
        nome: response.data['nome'] as String,
      );
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Primeiro acesso do membro — etapa 2: define a senha e ativa a conta.
  /// Já salva os tokens localmente, deixando o membro logado.
  Future<AuthModel> definirSenha({
    required String tokenSessao,
    required String senha,
  }) async {
    try {
      final response = await DioClient.identidade.post(
        '/auth/definir-senha',
        data: {'tokenSessao': tokenSessao, 'senha': senha},
      );

      final auth = AuthModel.fromJson(response.data);

      await _tokenDatasource.saveTokens(
        access: auth.accessToken,
        refresh: auth.refreshToken,
        role: auth.role,
        userId: auth.userId,
        atleticaId: auth.atleticaId,
      );

      return auth;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Extrai a mensagem de erro vinda do NestJS ({ statusCode, message, error }).
  /// Cai para uma mensagem genérica se a resposta não tiver esse formato.
  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List && message.isNotEmpty) return message.first.toString();
      return message.toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão esgotado. Verifique sua internet.';
    }
    return 'Não foi possível completar a operação. Tente novamente.';
  }
}