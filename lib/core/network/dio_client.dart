// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
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
      // passa o _instance para o interceptor — sem referência circular
      _instance!.interceptors.add(AuthInterceptor(_instance!));
    }
    return _instance!;
  }
}