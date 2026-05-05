import '../entities/auth_entity.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<(AuthEntity?, Failure?)> login(String email, String password);
  Future<Failure?> logout();
}