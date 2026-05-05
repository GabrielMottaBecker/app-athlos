import 'package:dio/dio.dart';
import '../models/auth_model.dart';
import 'token_local_datasource.dart';
import '../../core/network/dio_client.dart';

class AuthRemoteDatasource {
  static final _dio = DioClient.instance;

  static Future<AuthModel> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final auth = AuthModel.fromJson(res.data);
    await TokenLocalDatasource.saveTokens(auth.accessToken, auth.refreshToken);
    return auth;
  }

  static Future<void> refreshToken() async {
    final refreshToken = await TokenLocalDatasource.getRefreshToken();
    if (refreshToken == null) throw Exception('Sem refresh token');

    final res = await _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    final newAccess = res.data['accessToken'];
    await TokenLocalDatasource.saveTokens(newAccess, refreshToken);
  }

  static Future<void> logout() async {
    final refreshToken = await TokenLocalDatasource.getRefreshToken();
    await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    await TokenLocalDatasource.clearTokens();
  }
}