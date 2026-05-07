// lib/data/datasources/auth_remote_datasource.dart
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'token_local_datasource.dart';


class AuthRemoteDatasource {

  static Future<AuthModel> login(String email, String password) async {

  final members = MemberRepository().getAdminMembers();

  // Busca por email E senha ao mesmo tempo
  final member = members.cast<MemberModel?>().firstWhere(
    (m) => m!.email == email && m.senha == password,
    orElse: () => null,
  );

  // Se não achou nenhum membro com esse email+senha
  if (member == null) {
    throw Exception('Credenciais inválidas');
  }

  final String role;
  if (member.isAdmin) {
    role = 'admin';
  } else if (member.isPresident) {
    role = 'president';
  } else {
    role = 'user';
  }

  final auth = AuthModel(
    accessToken:  'mock_token_${member.id}',
    refreshToken: 'mock_refresh_${member.id}',
    role:         role,
  );

  await TokenLocalDatasource.saveTokens(
    auth.accessToken,
    auth.refreshToken,
    auth.role, // ← passa o role também
  );
  return auth;
}

  static Future<void> refreshToken() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No mock não precisa fazer nada
  }

  static Future<void> logout() async {
    await TokenLocalDatasource.clearTokens();
  }

  
}