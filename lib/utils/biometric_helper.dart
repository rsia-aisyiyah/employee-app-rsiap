import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is available (device supports AND user has enrolled)
  static Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate user with biometric
  static Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Verifikasi identitas Anda',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorMessage: 'Biometric tidak tersedia di perangkat ini',
          errorCode: BiometricErrorCode.notAvailable,
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return BiometricAuthResult(
        success: authenticated,
        errorMessage: authenticated ? null : 'Autentikasi gagal',
      );
    } on Exception catch (e) {
      // Handle specific error codes
      String errorMessage = 'Terjadi kesalahan';
      BiometricErrorCode errorCode = BiometricErrorCode.unknown;

      if (e.toString().contains(auth_error.notAvailable)) {
        errorMessage = 'Biometric tidak tersedia';
        errorCode = BiometricErrorCode.notAvailable;
      } else if (e.toString().contains(auth_error.notEnrolled)) {
        errorMessage = 'Belum ada fingerprint/Face ID yang terdaftar';
        errorCode = BiometricErrorCode.notEnrolled;
      } else if (e.toString().contains(auth_error.lockedOut) ||
          e.toString().contains(auth_error.permanentlyLockedOut)) {
        errorMessage = 'Terlalu banyak percobaan gagal. Coba lagi nanti';
        errorCode = BiometricErrorCode.lockedOut;
      } else if (e.toString().contains('UserCancel') ||
          e.toString().contains('CANCELED')) {
        errorMessage = 'Autentikasi dibatalkan';
        errorCode = BiometricErrorCode.userCanceled;
      }

      return BiometricAuthResult(
        success: false,
        errorMessage: errorMessage == 'Terjadi kesalahan'
            ? 'Error: ${e.toString()}'
            : errorMessage,
        errorCode: errorCode,
      );
    }
  }

  /// Stop authentication (if in progress)
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Result of biometric authentication
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final BiometricErrorCode? errorCode;

  BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });
}

/// Biometric error codes
enum BiometricErrorCode {
  notAvailable,
  notEnrolled,
  lockedOut,
  userCanceled,
  unknown,
}
