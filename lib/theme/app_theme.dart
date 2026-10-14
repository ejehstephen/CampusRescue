import 'package:flutter/material.dart';

class AppTheme {
  // DESIGN.md Inspired Surface & Background Tokens (Warm Dark Indigo / Slate)
  static const Color background = Color(
    0xFF0B101D,
  ); // Deep slate midnight canvas
  static const Color surface = Color(
    0xFF131B2E,
  ); // Primary card surface (Indigo slate)
  static const Color surfaceElevated = Color(
    0xFF1E293B,
  ); // Elevated element (Slate 800)
  static const Color surfaceHighlight = Color(
    0xFF28354D,
  ); // Active container background

  static const Color border = Color(
    0xFF26334D,
  ); // High-accessibility subtle border
  static const Color borderLight = Color(0xFF3B4D6C); // Active border
  static const Color borderFocus = Color(
    0xFF38BDF8,
  ); // Sky cyan highlight border

  // Signals & Action Accents (Vibrant & High Contrast)
  static const Color emergencyRed = Color(
    0xFFFF385C,
  ); // Friendly warm neon crimson red
  static const Color emergencyRedDark = Color(0xFFE11D48);
  static const Color emergencyRedLight = Color(0xFFFDA4AF);
  static const Color emergencyRedGlow = Color(0x55FF385C);

  static const Color warningAmber = Color(0xFFF59E0B); // Warm Amber Gold
  static const Color warningAmberLight = Color(0xFFFDE68A);
  static const Color warningAmberGlow = Color(0x44F59E0B);

  static const Color statusGreen = Color(0xFF10B981); // Soft Emerald Green
  static const Color statusGreenLight = Color(0xFF6EE7B7);
  static const Color statusGreenGlow = Color(0x4410B981);

  static const Color infoCyan = Color(0xFF06B6D4); // Electric Cyan
  static const Color infoCyanLight = Color(0xFF38BDF8); // Sky Cyan
  static const Color infoBlue = Color(0xFF3B82F6); // Bright Royal Blue
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Text Hierarchy Tokens (Legible, Warm & High Contrast)
  static const Color textPrimary = Color(
    0xFFF8FAFC,
  ); // Pure off-white for primary text
  static const Color textSecondary = Color(
    0xFF94A3B8,
  ); // Slate 400 for secondary details
  static const Color textMuted = Color(
    0xFF64748B,
  ); // Slate 500 for captions and hints

  static const String fontStack =
      'Segoe UI, -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: emergencyRed,
      colorScheme: const ColorScheme.dark(
        primary: emergencyRed,
        onPrimary: Colors.white,
        secondary: warningAmber,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceElevated,
        outline: border,
        error: emergencyRed,
        onError: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderFocus, width: 1.8),
        ),
      ),
    );
  }
}
