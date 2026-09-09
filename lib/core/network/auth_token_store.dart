import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore();
});

/// Web uses SharedPreferences; mobile/desktop use secure storage.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  static const _uuid = Uuid();
  static const _customerSessionTokenKey = 'customer_session_token';

  Future<String> readOrCreateClientSessionId() async {
    final existing = await _read(AppConstants.clientSessionStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _write(AppConstants.clientSessionStorageKey, created);
    return created;
  }

  Future<String?> readStaffAccessToken() =>
      _read(AppConstants.staffAccessTokenKey);

  Future<String?> readStaffRefreshToken() =>
      _read(AppConstants.staffRefreshTokenKey);

  Future<void> saveStaffAccessToken(String accessToken) async {
    await _write(AppConstants.staffAccessTokenKey, accessToken);
  }

  Future<void> saveStaffTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveStaffAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _write(AppConstants.staffRefreshTokenKey, refreshToken);
    }
  }

  Future<void> clearStaffTokens() async {
    await _delete(AppConstants.staffAccessTokenKey);
    await _delete(AppConstants.staffRefreshTokenKey);
  }

  Future<String?> readCustomerSessionToken() => _read(_customerSessionTokenKey);

  Future<void> saveCustomerSessionToken(String token) =>
      _write(_customerSessionTokenKey, token);

  Future<void> clearCustomerSessionToken() => _delete(_customerSessionTokenKey);

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secure.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await _secure.delete(key: key);
  }
}
