import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen_utils.dart';

class FitFormDesign {
  // ── Dark Palette (Current) ──────────────────────────────────────────────
  static const Color primary = Color(0xFFE8962A);
  static const Color secondary = Color(0xFF3D4470);
  static const Color darkBackground = Color(0xFF12103A);
  static const Color darkCard = Color(0xFF1E1B4B);
  static const Color darkSurface = Color(0xFF252248);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;

  // ── Light Palette (Soft Sky Pearl) ─────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F9FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEDF4FF);
  static const Color lightTextPrimary = Color(0xFF1A2A43);
  static const Color lightTextSecondary = Color(0xFF5A7B9A);

  // Dynamic getters based on context
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  
  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  // ── Gradients ────────────────────────────────────────────────────────────
  static LinearGradient primaryGradient(BuildContext context) => LinearGradient(
    colors: [
      primary,
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightSurface,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB347), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography helpers
  static TextStyle heading1(BuildContext context) => GoogleFonts.outfit(
    fontSize: context.sp(32),
    fontWeight: FontWeight.bold,
    color: textPrimary(context),
  );

  static TextStyle heading2(BuildContext context) => GoogleFonts.outfit(
    fontSize: context.sp(24),
    fontWeight: FontWeight.bold,
    color: textPrimary(context),
  );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: context.sp(18),
    color: textPrimary(context),
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: context.sp(16),
    color: Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: context.sp(14),
    color: Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary,
  );

  // Theme Data Generators
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      cardColor: darkCard,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primary,
      cardColor: lightCard,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
      ),
    );
  }

  // Border Radius
  static BorderRadius radiusM = BorderRadius.circular(16);
  static BorderRadius radiusL = BorderRadius.circular(24);

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

