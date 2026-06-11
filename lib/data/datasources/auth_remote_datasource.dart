import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import '../datasources/token_local_datasource.dart';
import '../../core/network/dio_client.dart';

class AuthRemoteDatasource {
  final TokenLocalDatasource _tokenDatasource;

  AuthRemoteDatasource({TokenLocalDatasource? tokenDatasource})
      : _tokenDatasource = tokenDatasource ?? TokenLocalDatasource();

  Future<AuthModel> login(String email, String password) async {
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
}