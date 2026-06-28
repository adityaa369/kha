import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricAuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return true;

      final canCheckBiometrics = await _auth.canCheckBiometrics;
      // If we can't check (e.g. no hardware), we allow access
      // If we can check but no fingerprints, authenticate() handles that
      if (!canCheckBiometrics) return true;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Khaata',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern fallback
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.passcodeNotSet ||
          e.code == auth_error.notEnrolled) {
        // Biometrics/PIN not available on device -> Allow access
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
