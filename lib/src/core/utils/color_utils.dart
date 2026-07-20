import 'package:flutter/material.dart';

/// Central color palette for the Hydrodok app.
///
/// Nature-inspired palette — dark forest greens, pale sage, earthy terracotta,
/// and clean off-whites. Designed for an agricultural / food-production feel.
class ColorUtils {
  ColorUtils._();

  // ── Core Palette ─────────────────────────────────────────────────────────

  /// 🌲 Dark Forest Green — primary brand color.
  /// Use for: primary CTAs ("Order"), category tags, active states.
  static const Color forestGreen = Color(0xFF365D39);

  /// 🌿 Pale Sage Green — secondary brand color.
  /// Use for: background sections, list-item highlights, header areas.
  static const Color sageGreen = Color(0xFFC7E5C7);

  /// 🧱 Earthy Terracotta — accent / high-energy CTA.
  /// Use for: high-priority actions ("Message Farm"), limited-use highlights.
  static const Color terracotta = Color(0xFFB3652D);

  /// 🫧 Off-White — neutral base.
  /// Use for: page backgrounds, inactive / disabled states.
  static const Color offWhite = Color(0xFFF9F9F9);

  /// 🤍 Pure White — crisp text / icon tint on dark surfaces.
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// 🌑 Deep Charcoal — dark text on light backgrounds.
  static const Color darkText = Color(0xFF2D3A2D);

  // ── Dark‑mode Surfaces ──────────────────────────────────────────────────

  /// Dark mode scaffold background — deep forest at night.
  static const Color darkBackground = Color(0xFF1A2A1A);

  /// Dark mode card / elevated surface.
  static const Color darkCard = Color(0xFF243624);

  /// Dark mode surface (slightly lighter than card).
  static const Color darkSurface = Color(0xFF2E402E);

  // ── Light‑mode Surfaces ─────────────────────────────────────────────────

  /// Light mode scaffold background.
  static const Color lightBackground = offWhite;

  /// Light mode card surface.
  static const Color lightCard = Color(0xFFFFFFFF);

  /// Light mode surface tint.
  static const Color lightSurface = Color(0xFFF0F5F0);

  // ── Semantic Aliases ────────────────────────────────────────────────────

  /// Primary CTA & brand identity.
  static const Color primary = forestGreen;

  /// Secondary backgrounds & highlights.
  static const Color secondary = sageGreen;

  /// High‑priority accent (use sparingly).
  static const Color accent = terracotta;

  /// Page / scaffold background.
  static const Color background = offWhite;

  /// Dark text on light surfaces.
  static const Color textDark = darkText;

  // ── Light Variants ──────────────────────────────────────────────────────

  /// 80 % primary — useful for pressed / hover states.
  static Color get primaryLight => primary.withValues(alpha: 0.8);

  /// 30 % accent — subtle glow / shadow tint.
  static Color get accentLight => accent.withValues(alpha: 0.3);

  // ── Gradients ────────────────────────────────────────────────────────────

  /// Lighter forest → forest green: primary brand gradient.
  /// Removes the near-black darkBackground so white text stays readable.
  static LinearGradient get mainGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A7C4E), forestGreen],
      );

  /// Terracotta → forest green: energetic CTA gradient.
  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [terracotta, forestGreen],
      );

  // ── Color Schemes ────────────────────────────────────────────────────────

  /// Dark color scheme — forest greens with off‑white text.
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
        primary: forestGreen,
        secondary: sageGreen,
        tertiary: terracotta,
        surface: darkSurface,
        onPrimary: pureWhite,
        onSecondary: darkText,
        onSurface: pureWhite,
        error: Color(0xFFCF6679),
      );

  /// Light color scheme — clean off‑white with forest‑green accents.
  static ColorScheme get lightColorScheme => const ColorScheme.light(
        primary: forestGreen,
        secondary: sageGreen,
        tertiary: terracotta,
        surface: lightSurface,
        onPrimary: pureWhite,
        onSecondary: darkText,
        onSurface: darkText,
        error: Color(0xFFB00020),
      );

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Shortcut for `color.withValues(alpha:)`.
  static Color withValues(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Linear interpolation between two colours.
  static Color blend(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }
}
