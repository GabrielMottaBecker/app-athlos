class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String role;
  final String userId; // 'user' | 'president' | 'admin'

  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
  });
}