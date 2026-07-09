import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Semantic colors (theme-independent)
  static const Color primary = Color(0xFF8B5CF6);
  static const Color income = Color(0xFF10B981);
  static const Color cost = Color(0xFFDC2626);
  static const Color savings = Color(0xFF3B82F6);

  // Psicologia del color para instituciones: azul profundo transmite
  // confianza y seguridad (bancos); ambar transmite energia de consumo y
  // precaucion (casas comerciales, credito de consumo).
  static const Color bankTrust = Color(0xFF2563EB);
  static const Color retailWarm = Color(0xFFF59E0B);

  // Dark theme colors
  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF141419);
  static const Color surfaceLight = Color(0xFF1E1E24);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Light theme colors
  static const Color _lightBackground = Color(0xFFF5F5F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1A1A2E);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightTextMuted = Color(0xFF9CA3AF);

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    bg: background,
    surf: surface,
    txtPrimary: textPrimary,
    txtSecondary: textSecondary,
    txtMuted: textMuted,
    borderColor: Colors.white.withValues(alpha: 0.05),
    inputBorderColor: Colors.white.withValues(alpha: 0.08),
  );

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    bg: _lightBackground,
    surf: _lightSurface,
    txtPrimary: _lightTextPrimary,
    txtSecondary: _lightTextSecondary,
    txtMuted: _lightTextMuted,
    borderColor: Colors.black.withValues(alpha: 0.08),
    inputBorderColor: Colors.black.withValues(alpha: 0.12),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surf,
    required Color txtPrimary,
    required Color txtSecondary,
    required Color txtMuted,
    required Color borderColor,
    required Color inputBorderColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: isDark
          ? ColorScheme.dark(surface: surf, primary: primary, secondary: income, error: cost)
          : ColorScheme.light(surface: surf, primary: primary, secondary: income, error: cost),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: txtPrimary, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: txtPrimary, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: txtPrimary),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: txtPrimary),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400, color: txtPrimary),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: txtSecondary),
        labelLarge: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: txtMuted),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: txtPrimary),
        iconTheme: IconThemeData(color: txtPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        hintStyle: GoogleFonts.outfit(color: txtMuted, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: txtSecondary, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: inputBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfaceLight : const Color(0xFF323232),
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
