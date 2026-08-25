import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginKey = 'last_login';
  static const String _loansKey = 'cached_loans';
  static const String _vacantChitsKey = 'cached_vacant_chits';
  static const String _myInvitesKey = 'cached_my_invites';
  static const String _myChitsKey = 'cached_my_chits';

  // Loans Caching
  static Future<void> saveCachedLoans(String json) async {
    await _storage.write(key: _loansKey, value: json);
  }

  static Future<String?> getCachedLoans() async {
    return await _storage.read(key: _loansKey);
  }

  static Future<void> deleteCachedLoans() async {
    await _storage.delete(key: _loansKey);
  }

  // Vacant Chits Caching
  static Future<void> saveCachedVacantChits(String json) async {
    await _storage.write(key: _vacantChitsKey, value: json);
  }

  static Future<String?> getCachedVacantChits() async {
    return await _storage.read(key: _vacantChitsKey);
  }

  static Future<void> deleteCachedVacantChits() async {
    await _storage.delete(key: _vacantChitsKey);
  }

  // My Invites Caching
  static Future<void> saveCachedMyInvites(String json) async {
    await _storage.write(key: _myInvitesKey, value: json);
  }

  static Future<String?> getCachedMyInvites() async {
    return await _storage.read(key: _myInvitesKey);
  }

  static Future<void> deleteCachedMyInvites() async {
    await _storage.delete(key: _myInvitesKey);
  }

  // My Chits Caching
  static Future<void> saveCachedMyChits(String json) async {
    await _storage.write(key: _myChitsKey, value: json);
  }

  static Future<String?> getCachedMyChits() async {
    return await _storage.read(key: _myChitsKey);
  }

  static Future<void> deleteCachedMyChits() async {
    await _storage.delete(key: _myChitsKey);
  }

    // Auth token methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // User data methods
  static Future<void> saveUserData(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Biometric settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Last login timestamp
  static Future<void> setLastLogin(DateTime dateTime) async {
    await _storage.write(key: _lastLoginKey, value: dateTime.toIso8601String());
  }

  static Future<DateTime?> getLastLogin() async {
    final value = await _storage.read(key: _lastLoginKey);
    return value != null ? DateTime.parse(value) : null;
  }

  // Clear only auth credentials — preserves loan/chit cache for next login
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _lastLoginKey);
  }

  // Clear all (full wipe — use only when user explicitly wants to erase all data)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}


