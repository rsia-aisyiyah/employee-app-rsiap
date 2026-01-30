import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys for storing credentials
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyNik = 'saved_nik';
  static const String _keyPassword = 'saved_password';

  /// Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Save credentials for biometric login
  static Future<bool> saveCredentials({
    required String nik,
    required String password,
  }) async {
    try {
      await _storage.write(key: _keyNik, value: nik);
      await _storage.write(key: _keyPassword, value: password);
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get saved credentials
  static Future<SavedCredentials?> getCredentials() async {
    try {
      final nik = await _storage.read(key: _keyNik);
      final password = await _storage.read(key: _keyPassword);

      if (nik != null && password != null) {
        return SavedCredentials(nik: nik, password: password);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete all saved credentials and disable biometric
  static Future<bool> deleteCredentials() async {
    try {
      await _storage.delete(key: _keyNik);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyBiometricEnabled);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric (without changing credentials)
  static Future<bool> enableBiometric() async {
    try {
      await _storage.write(key: _keyBiometricEnabled, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric (without deleting credentials)
  static Future<bool> disableBiometric() async {
    try {
      await _storage.write(key: _keyBiometricEnabled, value: 'false');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all secure storage (use with caution)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Saved credentials model
class SavedCredentials {
  final String nik;
  final String password;

  SavedCredentials({
    required this.nik,
    required this.password,
  });
}
