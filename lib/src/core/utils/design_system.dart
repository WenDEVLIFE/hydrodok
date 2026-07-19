import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_utils.dart';
import 'screen_utils.dart';

class FitFormDesign {
  // ── Dark Palette ────────────────────────────────────────────────────────
  static const Color primary = ColorUtils.forestGreen;
  static const Color secondary = ColorUtils.sageGreen;
  static const Color darkBackground = ColorUtils.darkBackground;
  static const Color darkCard = ColorUtils.darkCard;
  static const Color darkSurface = ColorUtils.darkSurface;
  static const Color darkTextPrimary = ColorUtils.pureWhite;
  static Color get darkTextSecondary => ColorUtils.pureWhite.withValues(alpha: 0.7);

  // ── Light Palette (Off-White + Sage) ────────────────────────────────────
  static const Color lightBackground = ColorUtils.offWhite;
  static const Color lightCard = ColorUtils.lightCard;
  static const Color lightSurface = ColorUtils.lightSurface;
  static const Color lightTextPrimary = ColorUtils.darkText;
  static Color get lightTextSecondary => ColorUtils.darkText.withValues(alpha: 0.6);

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

  static LinearGradient get accentGradient =>
      const LinearGradient(
        colors: [ColorUtils.terracotta, ColorUtils.forestGreen],
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
        color: Theme.of(context).brightness == Brightness.dark
            ? darkTextSecondary
            : lightTextSecondary,
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
        fontSize: context.sp(14),
        color: Theme.of(context).brightness == Brightness.dark
            ? darkTextSecondary
            : lightTextSecondary,
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
        primary: ColorUtils.forestGreen,
        secondary: ColorUtils.sageGreen,
        surface: ColorUtils.darkSurface,
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
        primary: ColorUtils.forestGreen,
        secondary: ColorUtils.sageGreen,
        surface: ColorUtils.lightSurface,
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
