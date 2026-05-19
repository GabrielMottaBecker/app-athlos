// lib/core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenLocalDatasource _tokenDatasource;
  final AuthRemoteDatasource _authDatasource;

  AuthInterceptor(
    this.dio, {
    TokenLocalDatasource? tokenDatasource,
    AuthRemoteDatasource? authDatasource,
  })  : _tokenDatasource = tokenDatasource ?? TokenLocalDatasource(),
        _authDatasource = authDatasource ?? AuthRemoteDatasource();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenDatasource.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        await _authDatasource.refreshToken();
        final token = await _tokenDatasource.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final retry = await dio.fetch(err.requestOptions);
        return handler.resolve(retry);
      } catch (_) {
        await _tokenDatasource.clearTokens();
        // navegar para /login
      }
    }
    handler.next(err);
  }
}