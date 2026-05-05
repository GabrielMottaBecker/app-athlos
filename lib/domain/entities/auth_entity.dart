class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String role; // 'user' | 'president' | 'admin'

  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });
}