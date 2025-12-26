import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica se il dispositivo supporta la biometria
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il tipo di biometria (Face ID / Touch ID)
  static Future<String> getBiometricTypeName() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Touch ID';
      }
      return 'biometria';
    } catch (e) {
      return 'biometria';
    }
  }

  /// Esegue l'autenticazione biometrica
  static Future<bool> authenticate({required String reason}) async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (e) {
      print('❌ Errore autenticazione: $e');
      return false;
    }
  }
}
