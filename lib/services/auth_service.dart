import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'is_biometric_enabled';

  // Verifica se il dispositivo ha l'hardware (FaceID/TouchID)
  static Future<bool> isDeviceSupported() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  // Legge se l'utente ha attivato la funzione nelle impostazioni
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  // Salva la preferenza dell'utente
  static Future<void> setBiometricEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isEnabled);
  }

  // Richiede l'autenticazione (mostra il popup di sistema)
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Autenticati per accedere',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Errore Auth: $e');
      return false;
    }
  }
}
