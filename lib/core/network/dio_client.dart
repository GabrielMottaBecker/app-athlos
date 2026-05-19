// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';
import 'auth_interceptor.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(BaseOptions(
        baseUrl: 'https://sua-api.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));
      _instance!.interceptors.add(
        AuthInterceptor(
          _instance!,
          tokenDatasource: TokenLocalDatasource(),
          authDatasource: AuthRemoteDatasource(),
        ),
      );
    }
    return _instance!;
  }
}