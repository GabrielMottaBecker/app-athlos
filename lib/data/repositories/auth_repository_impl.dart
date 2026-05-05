import 'package:dio/dio.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<(AuthEntity?, Failure?)> login(String email, String password) async {
    try {
      final auth = await AuthRemoteDatasource.login(email, password);
      return (auth, null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return (null, const UnauthorizedFailure('Email ou senha inválidos'));
      }
      return (null, ServerFailure(e.message ?? 'Erro no servidor'));
    }
  }

  @override
  Future<Failure?> logout() async {
    try {
      await AuthRemoteDatasource.logout();
      return null;
    } catch (_) {
      return const ServerFailure('Erro ao fazer logout');
    }
  }
}