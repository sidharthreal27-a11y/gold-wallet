// biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return canCheck && isDeviceSupported;
  }

  Future<List<BiometricType>> availableBiometrics() {
    return _auth.getAvailableBiometrics();
  }

  /// Returns true only on a genuine successful biometric/device-credential
  /// check. Any exception (lockout, not enrolled, cancelled) resolves to false
  /// rather than throwing, so callers can fall back to PIN entry.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN/pattern as fallback
          stickyAuth: true,
        ),
      );
    } on Exception catch (e) {
      if (e.toString().contains(auth_error.notAvailable) ||
          e.toString().contains(auth_error.notEnrolled)) {
        return false;
      }
      return false;
    }
  }
}
