import 'package:flutter/material.dart';

/// Atajos de tema usados por toda la UI para evitar repetir
/// `Theme.of(context)...` y los cálculos de color dependientes del brillo.
extension ContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;

  bool get isDark => theme.brightness == Brightness.dark;

  /// Color de las superficies tipo tarjeta.
  Color get surfaceColor => theme.colorScheme.surface;

  /// Borde sutil para tarjetas y contenedores.
  Color get cardBorderColor => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.08);

  /// Borde para campos de entrada (un poco más marcado que el de tarjeta).
  Color get inputBorderColor => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.12);

  /// Color de los divisores.
  Color get dividerColor => isDark ? Colors.white12 : Colors.black12;

  /// Texto principal sobre superficies.
  Color? get primaryTextColor => textTheme.bodyLarge?.color;

  /// Texto secundario (etiquetas, descripciones).
  Color? get secondaryTextColor => textTheme.bodyMedium?.color;

  /// Texto atenuado (metadatos, ayudas).
  Color? get mutedTextColor => textTheme.labelLarge?.color;
}
