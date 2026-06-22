import 'dart:convert';
import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.accessToken,
    required super.refreshToken,
    required super.role,
    required super.userId,
    this.atleticaId,
  });

  final String? atleticaId;

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String;
    final refreshToken = json['refreshToken'] as String;

    // Decodifica o payload do JWT (parte do meio, base64)
    final parts = accessToken.split('.');
    final payload = parts[1];

    // Base64 precisa de padding
    final normalized = base64Url.normalize(payload);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));

        // role vem das permissions — verifica super_admin primeiro
    final permissions = List<String>.from(decoded['permissions'] ?? []);
    final String role;
    if (permissions.contains('super_admin')) {
      role = 'SUPER_ADMIN';
    } else if (permissions.contains('users:write')) {
      role = 'ADMINISTRADOR';
    } else {
      role = 'MEMBRO';
    }

    // Super admin não pertence a nenhuma atlética — ignora o campo do JWT
    final atleticaId = role == 'SUPER_ADMIN'
        ? null
        : decoded['atleticaId'] as String?;

    return AuthModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
      userId: decoded['sub'] as String,
      atleticaId: atleticaId,
    );
  }
}