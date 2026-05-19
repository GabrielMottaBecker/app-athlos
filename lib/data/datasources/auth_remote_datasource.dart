import '../models/models.dart';
import '../repositories/repositories.dart';
import 'token_local_datasource.dart';
import '../models/auth_model.dart';

class AuthRemoteDatasource {
  final TokenLocalDatasource _tokenDatasource;

  AuthRemoteDatasource({TokenLocalDatasource? tokenDatasource})
      : _tokenDatasource = tokenDatasource ?? TokenLocalDatasource();

  Future<AuthModel> login(String email, String password) async {
    final members = MemberRepository().getAdminMembers();

    final member = members.cast<MemberModel?>().firstWhere(
      (m) => m!.email == email && m.senha == password,
      orElse: () => null,
    );

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
      userId:       member.id.toString(), 
    );

    await _tokenDatasource.saveTokens(
      access:  auth.accessToken,
      refresh: auth.refreshToken,
      role:    auth.role,
      userId:  auth.userId,
    );

    return auth;
  }

  Future<void> refreshToken() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> logout() async {
    await _tokenDatasource.clearTokens();
  }
}