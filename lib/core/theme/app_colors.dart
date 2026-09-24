import 'package:flutter/material.dart';

/// FitStack Design System Colors ("Kinetic Discipline" Palette)
abstract class AppColors {
  // Signal Performance Greens (Brand Constants)
  static const Color primary = Color(0xFF047857); // Primary CTA & active streaks
  static const Color metricGreen = Color(0xFF10B981); // Telemetry ring & live timer
  static const Color surfaceTint = Color(0xFF00714D);

  // Neutrals (Light Mode)
  static const Color background = Color(0xFFF8F9FA); // App background canvas
  static const Color cardSurface = Color(0xFFFFFFFF); // Data card surface
  static const Color textPrimary = Color(0xFF111827); // Headlines & primary values
  static const Color textSecondary = Color(0xFF374151); // Body text & labels
  static const Color textMuted = Color(0xFF6B7280); // Metadata, units, timestamps
  static const Color borderSubdued = Color(0xFFE5E7EB); // Dividers & perimeters
  static const Color surfaceSubdued = Color(0xFFF3F4F6); // Trackers & disabled state
  static const Color accentSubtle = Color(0xFFECFDF5); // Selected state background fill

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkBorder = Color(0xFF334155);     // Slate 700
  static const Color darkSurfaceSubdued = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkAccentSubtle = Color(0xFF064E3B);

  // Dynamic Theme Resolvers based on current context brightness
  static Color ofBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : background;

  static Color ofCardSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : cardSurface;

  static Color ofTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  static Color ofTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  static Color ofTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : textMuted;

  static Color ofBorderSubdued(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : borderSubdued;

  static Color ofSurfaceSubdued(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceSubdued : surfaceSubdued;

  static Color ofAccentSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkAccentSubtle : accentSubtle;
}

extension AppThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get bg => AppColors.ofBackground(this);
  Color get cardBg => AppColors.ofCardSurface(this);
  Color get txtPrimary => AppColors.ofTextPrimary(this);
  Color get txtSecondary => AppColors.ofTextSecondary(this);
  Color get txtMuted => AppColors.ofTextMuted(this);
  Color get border => AppColors.ofBorderSubdued(this);
  Color get surfaceSubdued => AppColors.ofSurfaceSubdued(this);
  Color get accentSubtle => AppColors.ofAccentSubtle(this);
}
