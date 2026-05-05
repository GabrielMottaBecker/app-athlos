abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure     extends Failure { const ServerFailure(super.message); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure(super.message); }
class NetworkFailure    extends Failure { const NetworkFailure(super.message); }