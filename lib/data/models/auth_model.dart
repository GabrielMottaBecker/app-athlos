import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.accessToken,
    required super.refreshToken,
    required super.role,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
    accessToken:  json['accessToken'],
    refreshToken: json['refreshToken'],
    role:         json['role'], 
  );
}