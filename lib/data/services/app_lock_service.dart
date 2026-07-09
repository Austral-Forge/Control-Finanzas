import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bloqueo local de la app con PIN. El PIN nunca se guarda en claro: se
/// almacena un hash SHA-256 con salt aleatorio, por lo que no es recuperable
/// desde las preferencias del dispositivo.
class AppLockService {
  static const String _pinHashKey = 'app_lock_pin_hash';
  static const String _pinSaltKey = 'app_lock_pin_salt';
  static const int pinLength = 4;

  /// Inyectable para tests; en producción usa las preferencias reales.
  final Future<SharedPreferences> Function() _prefsProvider;

  AppLockService({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  Future<bool> isEnabled() async {
    final prefs = await _prefsProvider();
    return prefs.containsKey(_pinHashKey);
  }

  Future<void> setPin(String pin) async {
    final prefs = await _prefsProvider();
    final salt = _generateSalt();
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, _hash(pin, salt));
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await _prefsProvider();
    final salt = prefs.getString(_pinSaltKey);
    final storedHash = prefs.getString(_pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  Future<void> disable() async {
    final prefs = await _prefsProvider();
    await prefs.remove(_pinHashKey);
    await prefs.remove(_pinSaltKey);
  }

  static bool isValidPinFormat(String pin) =>
      pin.length == pinLength && int.tryParse(pin) != null;

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
