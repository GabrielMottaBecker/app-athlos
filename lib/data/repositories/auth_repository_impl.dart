import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl({AuthRemoteDatasource? datasource})
      : _datasource = datasource ?? AuthRemoteDatasource();

  @override
  Future<(AuthEntity?, Failure?)> login(String email, String password) async {
    try {
      final auth = await _datasource.login(email, password);
      return (auth, null);
    } catch (e) {
      return (null, UnauthorizedFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<Failure?> logout() async {
    try {
      await _datasource.logout();
      return null;
    } catch (_) {
      return const ServerFailure('Erro ao fazer logout');
    }
  }
}