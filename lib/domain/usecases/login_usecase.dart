import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';
import '../../core/errors/failures.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<(AuthEntity?, Failure?)> call(String email, String password) {
    return repository.login(email, password);
  }
}