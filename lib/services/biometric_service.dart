import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'biometric_enabled';

  /// Verifica se l'hardware è disponibile e configurato
  static Future<bool> isAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint("Errore verifica disponibilità: $e");
      return false;
    }
  }

  /// Ottiene il nome (Face ID / Touch ID)
  static Future<String> getBiometricTypeName() async {
    try {
      if (!await isAvailable()) return 'Biometria';
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.contains(BiometricType.face)) return 'Face ID';
      if (availableBiometrics.contains(BiometricType.fingerprint)) return 'Touch ID';
    } catch (_) {}
    return 'Biometria';
  }

  /// Legge la preferenza salvata
  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Salva la preferenza
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    debugPrint("🔐 Biometrico salvato: $enabled");
  }

  /// Tenta l'autenticazione.
  /// SU IOS: La prima volta che chiami questo metodo, il sistema chiede i permessi.
  static Future<bool> authenticate({String reason = 'Autenticati per accedere'}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,      // Mantiene il popup se l'app va in background
          biometricOnly: true,   // Forza l'uso biometrico
          useErrorDialogs: true, // Mostra errori di sistema se fallisce
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("❌ Errore Auth: ${e.code} - ${e.message}");
      if (e.code == auth_error.notAvailable || e.code == auth_error.passcodeNotSet) {
        // Qui potresti mostrare un avviso che l'hardware non è pronto
        return false;
      }
      // Se l'utente nega il permesso (auth_error.notEnrolled o simile)
      return false;
    }
  }
}
