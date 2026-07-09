import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Variante nativa (Android/iOS/Windows/Linux/macOS): inicializa el motor
/// sqlite3 vía FFI. Solo se invoca en Windows/Linux, donde el plugin
/// `sqflite` normal no tiene implementación de plataforma.
DatabaseFactory get desktopDatabaseFactory {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}
