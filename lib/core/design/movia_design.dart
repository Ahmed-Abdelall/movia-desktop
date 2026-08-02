import 'package:flutter/material.dart';

abstract final class MoviaDesign {
  static const purple = Color(0xFF6657E8);
  static const blue = Color(0xFF3B82F6);
  static const navy = Color(0xFF11162A);
  static const canvas = Color(0xFFF6F7FB);
  static const darkCanvas = Color(0xFF0B1020);
  static const radiusSmall = 10.0;
  static const radius = 18.0;
  static const radiusLarge = 24.0;

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: purple,
      brightness: brightness,
      surface: dark ? const Color(0xFF141A2C) : Colors.white,
    );
    final border = dark ? const Color(0xFF293149) : const Color(0xFFE5E7EF);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? darkCanvas : canvas,
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? const Color(0xFF141A2C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF111729) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
    );
  }
}
