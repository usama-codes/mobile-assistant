import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for the app.
/// Dark-first, calm, low-friction aesthetic.
class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0E0F12);
  static const Color surface = Color(0xFF16181D);
  static const Color surfaceVariant = Color(0xFF1E2028);
  static const Color border = Color(0xFF2A2C35);
  static const Color accent = Color(0xFF2DD4BF); // desaturated teal
  static const Color accentDim = Color(0x332DD4BF); // accent at 20% opacity
  static const Color textPrimary = Color(0xE6FFFFFF); // 90% white
  static const Color textSecondary = Color(0x99FFFFFF); // 60% white
  static const Color textDisabled = Color(0x40FFFFFF); // 25% white

  // Priority colors — low-key, border-only use
  static const Color priorityLow = Color(0xFF4ADE80);
  static const Color priorityMedium = Color(0xFFFBBF24);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityCritical = Color(0xFFEF4444);

  // ── Geometry ─────────────────────────────────────────────────────────────
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusPill = 999;

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme get _textTheme => GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
            fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: GoogleFonts.manrope(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.manrope(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.manrope(fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.manrope(fontSize: 12, color: textSecondary),
        labelSmall: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.w500, color: textDisabled),
      );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        primary: accent,
        onPrimary: background,
        secondary: accent,
        onSecondary: background,
        outline: border,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      textTheme: _textTheme,
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(color: textDisabled, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: accentDim,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.manrope(color: textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
        ),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: GoogleFonts.manrope(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accent : Colors.transparent),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  // ── Light Theme (minimal — app is dark-first) ─────────────────────────────
  static ThemeData get light {
    const lightSurface = Color(0xFFFFFFFF);
    const lightBackground = Color(0xFFF5F5F7);
    const lightSurfaceVariant = Color(0xFFEEEEF2);
    const lightBorder = Color(0xFFDDDDE5);
    const lightText = Color(0xFF1A1A2E);
    const lightTextSecondary = Color(0xFF5A5A72);

    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      cardColor: lightSurface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurface: lightText,
        onSurfaceVariant: lightTextSecondary,
        outline: lightBorder,
        primary: accent,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: lightText),
        titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: lightText),
        bodyLarge: GoogleFonts.manrope(fontSize: 15, color: lightText),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: lightTextSecondary),
        bodySmall: GoogleFonts.manrope(fontSize: 12, color: lightTextSecondary),
        labelSmall: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: lightTextSecondary),
      ),
      iconTheme: const IconThemeData(color: lightTextSecondary, size: 22),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 0),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: const BorderSide(color: lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(color: lightTextSecondary.withValues(alpha: 0.6), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceVariant,
        selectedColor: accentDim,
        side: const BorderSide(color: lightBorder),
        labelStyle: GoogleFonts.manrope(color: lightTextSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: GoogleFonts.manrope(color: lightText, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusL)),
        ),
        elevation: 0,
      ),
    );
  }

  // ── Priority helpers ──────────────────────────────────────────────────────
  static Color priorityColor(dynamic priority) {
    final name = priority.toString().split('.').last.toLowerCase();
    switch (name) {
      case 'low': return priorityLow;
      case 'high': return priorityHigh;
      case 'critical': return priorityCritical;
      default: return priorityMedium;
    }
  }
}

