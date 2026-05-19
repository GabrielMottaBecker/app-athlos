import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  Future<Failure?> call() => repository.logout();
}