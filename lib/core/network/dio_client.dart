import 'package:dio/dio.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/token_local_datasource.dart';
import 'auth_interceptor.dart';

class DioClient {
  static Dio? _identidade;
  static Dio? _associacao;
  static Dio? _feed;
  static Dio? _financeiro;
  static Dio? _lojinha;
  static Dio? _notificacoes;

  static Dio _make(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(
      AuthInterceptor(
        dio,
        tokenDatasource: TokenLocalDatasource(),
        authDatasource: AuthRemoteDatasource(),
      ),
    );
    return dio;
  }

  static Dio get identidade =>
      _identidade ??= _make('http://localhost:4002/v1');

  static Dio get associacao =>
      _associacao ??= _make('http://localhost:4001/v1');

  static Dio get feed =>
      _feed ??= _make('http://localhost:4003/v1');

  static Dio get financeiro =>
      _financeiro ??= _make('http://localhost:4004/v1');

  static Dio get lojinha =>
      _lojinha ??= _make('http://localhost:4005/v1');

  static Dio get notificacoes =>
      _notificacoes ??= _make('http://localhost:4006/v1');
}