// lib/core/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio; // <-- recebe o Dio de fora, sem importar DioClient

  AuthInterceptor(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenLocalDatasource.getAccessToken();
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
        await AuthRemoteDatasource.refreshToken();
        final token = await TokenLocalDatasource.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final retry = await dio.fetch(err.requestOptions); // usa o dio injetado
        return handler.resolve(retry);
      } catch (_) {
        await TokenLocalDatasource.clearTokens();
        // navegar para /login
      }
    }
    handler.next(err);
  }
}