import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._(); // Private constructor to prevent instantiation

  // ── Logo-derived Palette ─────────────────────────────────────────────────
  /// 🟠 Warm Amber — primary brand accent (muscle highlight from logo)
  static const Color warmAmber = Color(0xFFE8962A);

  /// 🔵 Slate Blue — secondary brand color (character clothing in logo)
  static const Color slateBlue = Color(0xFF3D4470);

  /// 🌑 Deep Navy — logo background color
  static const Color deepNavy = Color(0xFF12103A);

  /// 🌒 Navy Card — elevated card surface
  static const Color navyCard = Color(0xFF1E1B4B);

  /// 🟡 Golden Orange — highlight / call-to-action accent
  static const Color goldenOrange = Color(0xFFFFB347);

  /// 🤍 Pure White — text and icon color
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// ⬛ Soft Black — deep charcoal for text
  static const Color softBlack = Color(0xFF2E2E3A);

  // ============================================
  // Semantic Color Names
  // ============================================

  /// Primary brand color
  static const Color primary = warmAmber;

  /// Background color
  static const Color background = deepNavy;

  /// Accent color
  static const Color accent = goldenOrange;

  /// Secondary brand color
  static const Color secondary = slateBlue;

  /// Text color for dark text on light backgrounds
  static const Color textDark = softBlack;

  /// Light version of amber
  static final Color primaryLight = warmAmber.withValues(alpha: 0.8);

  /// Darker navy for deep backgrounds
  static const Color primaryDark = Color(0xFF0A0928);

  /// Light version of golden accent
  static final Color accentLight = goldenOrange.withValues(alpha: 0.3);

  // ============================================
  // Gradients
  // ============================================

  /// Orange → deep navy: core brand gradient
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmAmber, deepNavy],
  );

  /// Amber → slate blue: button & highlight gradient
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldenOrange, warmAmber],
  );

  // ============================================
  // Color Schemes
  // ============================================

  /// Dark color scheme for the app (primary mode)
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
    primary: warmAmber,
    secondary: slateBlue,
    tertiary: goldenOrange,
    surface: navyCard,
    onPrimary: pureWhite,
    onSecondary: pureWhite,
    onSurface: pureWhite,
    error: Color(0xFFCF6679),
  );

  /// Light color scheme for the app (fallback)
  static ColorScheme get lightColorScheme => ColorScheme.light(
    primary: warmAmber,
    secondary: slateBlue,
    tertiary: goldenOrange,
    surface: pureWhite,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: softBlack,
    error: Colors.redAccent,
  );

  // ============================================
  // Helper methods
  // ============================================

  /// Get a color with custom alpha/opacity
  static Color withValues(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Blend two colors together
  static Color blend(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }
}

