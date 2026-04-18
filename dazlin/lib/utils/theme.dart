// lib/utils/theme.dart
import 'package:flutter/material.dart';

class DazlinTheme {
  // Core palette — neon lime on deep charcoal
  static const Color bg         = Color(0xFF0A0D0A);
  static const Color surface    = Color(0xFF111611);
  static const Color surfaceAlt = Color(0xFF161D16);
  static const Color card       = Color(0xFF1A221A);
  static const Color cardHover  = Color(0xFF1F2A1F);
  static const Color border     = Color(0xFF2A372A);

  static const Color lime       = Color(0xFFB5F23A);
  static const Color limeDeep   = Color(0xFF8BC820);
  static const Color limeFade   = Color(0x33B5F23A);
  static const Color limeGlow   = Color(0x55B5F23A);

  static const Color sent       = Color(0xFF1E3A1E);
  static const Color sentBorder = Color(0xFF2D5A2D);
  static const Color received   = Color(0xFF1A221A);

  static const Color textPrimary   = Color(0xFFF0F5F0);
  static const Color textSecondary = Color(0xFF8A9E8A);
  static const Color textMuted     = Color(0xFF4A5A4A);
  static const Color textOnLime    = Color(0xFF0A0D0A);

  static const Color online  = Color(0xFF4ADE80);
  static const Color offline = Color(0xFF4A5A4A);
  static const Color unread  = lime;

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Sora',
    colorScheme: const ColorScheme.dark(
      primary: lime,
      secondary: limeDeep,
      surface: surface,
      onSurface: textPrimary,
      onPrimary: textOnLime,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lime, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lime,
        foregroundColor: textOnLime,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
