import 'package:sqflite/sqflite.dart';

/// Variante para web: nunca se invoca (el helper usa IndexedDB en ese caso),
/// pero debe existir para que el import condicional resuelva sin arrastrar
/// `dart:ffi` (no disponible en el compilador de web) al build.
DatabaseFactory get desktopDatabaseFactory => throw UnsupportedError(
    'La base de datos de escritorio no esta disponible en esta plataforma.');
