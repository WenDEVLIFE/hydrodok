import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A centralized typography utility class that provides consistent text styles
/// throughout the app. Can be called anywhere with AppAppTypography.heading1(), etc.
///
/// Uses Playfair Display for elegant headings and Inter for clean body text.
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // Base font weights
  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semiBold = FontWeight.w600;
  static const FontWeight _bold = FontWeight.w700;

  /// Large heading - typically for page titles
  /// Uses Playfair Display for elegant serif look
  /// Usage: Text('Title', style: AppTypography.heading1())
  static TextStyle heading1({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? 32,
      fontWeight: fontWeight ?? _bold,
      color: color,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Medium heading - for section titles
  /// Uses Playfair Display for elegant serif look
  /// Usage: Text('Section', style: AppTypography.heading2())
  static TextStyle heading2({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? 28,
      fontWeight: fontWeight ?? _bold,
      color: color,
      height: 1.25,
      letterSpacing: -0.3,
    );
  }

  /// Smaller heading - for subsections
  /// Uses Playfair Display for elegant serif look
  /// Usage: Text('Subsection', style: AppTypography.heading3())
  static TextStyle heading3({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? _semiBold,
      color: color,
      height: 1.3,
      letterSpacing: -0.2,
    );
  }

  /// Small heading - for card titles or list headers
  /// Uses Playfair Display for elegant serif look
  /// Usage: Text('Card Title', style: AppTypography.heading4())
  static TextStyle heading4({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize ?? 20,
      fontWeight: fontWeight ?? _semiBold,
      color: color,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  /// Standard body text - for paragraphs
  /// Uses Inter for clean, readable sans-serif
  /// Usage: Text('This is body text', style: AppTypography.bodyLarge())
  static TextStyle bodyLarge({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? _regular,
      color: color,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  /// Medium body text - for most content
  /// Uses Inter for clean, readable sans-serif
  /// Usage: Text('Regular text', style: AppTypography.bodyMedium())
  static TextStyle bodyMedium({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? _regular,
      color: color,
      height: 1.5,
      letterSpacing: 0.25,
    );
  }

  /// Small body text - for secondary content
  /// Uses Inter for clean, readable sans-serif
  /// Usage: Text('Small text', style: AppTypography.bodySmall())
  static TextStyle bodySmall({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? _regular,
      color: color,
      height: 1.5,
      letterSpacing: 0.4,
    );
  }

  /// Button text style
  /// Uses Inter for UI consistency
  /// Usage: Text('BUTTON', style: AppTypography.button())
  static TextStyle button({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? _semiBold,
      color: color,
      height: 1.2,
      letterSpacing: 1.25,
    );
  }

  /// Caption text - for hints, labels
  /// Uses Inter for UI consistency
  /// Usage: Text('Caption', style: AppTypography.caption())
  static TextStyle caption({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? _regular,
      color: color,
      height: 1.3,
      letterSpacing: 0.4,
    );
  }

  /// Overline text - for labels, tags
  /// Uses Inter for UI consistency
  /// Usage: Text('LABEL', style: AppTypography.overline())
  static TextStyle overline({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 10,
      fontWeight: fontWeight ?? _medium,
      color: color,
      height: 1.5,
      letterSpacing: 1.5,
    );
  }

  /// Subtitle - larger than body, smaller than heading
  /// Uses Inter for clean readability
  /// Usage: Text('Subtitle', style: AppTypography.subtitle1())
  static TextStyle subtitle1({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? _medium,
      color: color,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  /// Smaller subtitle
  /// Uses Inter for clean readability
  /// Usage: Text('Subtitle', style: AppTypography.subtitle2())
  static TextStyle subtitle2({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? _medium,
      color: color,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }
}
