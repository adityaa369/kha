import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastLoginKey = 'last_login';

  // Auth token methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
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

  // Clear all (useful for logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
