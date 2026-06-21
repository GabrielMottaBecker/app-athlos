import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenLocalDatasource {
  // Singleton
  static final TokenLocalDatasource _instance = TokenLocalDatasource._internal();
  factory TokenLocalDatasource({FlutterSecureStorage? storage}) => _instance;
  TokenLocalDatasource._internal() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey   = 'access_token';
  static const _refreshKey  = 'refresh_token';
  static const _roleKey     = 'role';
  static const _userIdKey   = 'user_id';
  static const _atleticaKey = 'atletica_id';
  static const _expiryKey   = 'token_expiry';

  static const _sessionDuration = Duration(hours: 24);

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedRole;
  String? _cachedUserId;
  String? _cachedAtleticaId;
  DateTime? _cachedExpiry;

  Future<void> saveTokens({
    required String access,
    required String refresh,
    required String role,
    required String userId,
    String? atleticaId,
  }) async {
    final expiry = DateTime.now().toUtc().add(_sessionDuration);

    await Future.wait([
      _storage.write(key: _accessKey,  value: access),
      _storage.write(key: _refreshKey, value: refresh),
      _storage.write(key: _roleKey,    value: role),
      _storage.write(key: _userIdKey,  value: userId),
      _storage.write(key: _expiryKey,  value: expiry.toIso8601String()),
      if (atleticaId != null)
        _storage.write(key: _atleticaKey, value: atleticaId),
    ]);

    _cachedAccessToken  = access;
    _cachedRefreshToken = refresh;
    _cachedRole         = role;
    _cachedUserId       = userId;
    _cachedAtleticaId   = atleticaId;
    _cachedExpiry       = expiry;
  }

  Future<String?> getAccessToken() async {
    if (_cachedExpiry != null) {
      if (DateTime.now().toUtc().isAfter(_cachedExpiry!)) {
        await clearTokens();
        return null;
      }
      return _cachedAccessToken;
    }

    final expiry = await _read(_expiryKey);
    if (expiry == null) return null;

    final expiryDate = DateTime.tryParse(expiry);
    if (expiryDate == null || DateTime.now().toUtc().isAfter(expiryDate)) {
      await clearTokens();
      return null;
    }

    _cachedExpiry      = expiryDate;
    _cachedAccessToken = await _read(_accessKey);
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    _cachedRefreshToken ??= await _read(_refreshKey);
    return _cachedRefreshToken;
  }

  Future<String?> getRole() async {
    _cachedRole ??= await _read(_roleKey);
    return _cachedRole;
  }

  Future<String?> getUserId() async {
    _cachedUserId ??= await _read(_userIdKey);
    return _cachedUserId;
  }

  Future<String?> getAtleticaId() async {
    _cachedAtleticaId ??= await _read(_atleticaKey);
    return _cachedAtleticaId;
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _atleticaKey),
      _storage.delete(key: _expiryKey),
    ]);
    _clearCache();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    _clearCache();
  }

  void _clearCache() {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    _cachedRole         = null;
    _cachedUserId       = null;
    _cachedAtleticaId   = null;
    _cachedExpiry       = null;
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}