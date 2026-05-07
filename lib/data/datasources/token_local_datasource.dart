import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenLocalDatasource {
  static const _storage    = FlutterSecureStorage();
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey    = 'role'; // ← novo

  static Future<void> saveTokens(String access, String refresh, String role) async {
    await _storage.write(key: _accessKey,  value: access);
    await _storage.write(key: _refreshKey, value: refresh);
    await _storage.write(key: _roleKey,    value: role);
  }

  static Future<String?> getAccessToken()  => _storage.read(key: _accessKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  static Future<String?> getRole()         => _storage.read(key: _roleKey); 

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}