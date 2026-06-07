import 'package:flutter/material.dart';
import 'package:pratik_app_kit/pratik_app_kit.dart';

/// Light palette — Emerald green growth theme.
class HabitForgeColors extends AppColorsBase {
  // Primary — Emerald Green (growth, habits, nature)
  @override
  Color get primary => const Color(0xFF10B981);
  @override
  Color get primaryLight => const Color(0xFFECFDF5);
  Color get primaryDark => const Color(0xFF059669);

  // Secondary — Amber (streaks, fire, energy)
  @override
  Color get secondary => const Color(0xFFF59E0B);
  Color get secondaryLight => const Color(0xFFFFFBEB);
  Color get secondaryDark => const Color(0xFFD97706);

  // Accent — Indigo (stats, charts, depth)
  Color get accent => const Color(0xFF6366F1);
  Color get accentLight => const Color(0xFFEEF2FF);

  // Backgrounds
  @override
  Color get scaffoldBg => const Color(0xFFF0FDF4);
  @override
  Color get cardBg => const Color(0xFFFFFFFF);
  @override
  Color get surfaceBg => const Color(0xFFE8F5E9);
  Color get surfaceLight => const Color(0xFFE8F5E9);

  // Text
  @override
  Color get textPrimary => const Color(0xFF1B2E1F);
  @override
  Color get textSecondary => const Color(0xFF4A6B52);
  Color get textTertiary => const Color(0xFF8FA897);

  // Functional (required by AppColorsBase)
  @override
  Color get error => const Color(0xFFB00020);
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get onSurface => const Color(0xFF1B2E1F);

  // Habit-specific accents
  static const streakFire = Color(0xFFEF4444);
  static const streakFireBg = Color(0xFFFEF2F2);
  static const checkGreen = Color(0xFF16A34A);
  static const missedRed = Color(0xFFDC2626);
  static const frozenBlue = Color(0xFF3B82F6);

  // Heatmap gradient (light to dark green)
  static const heatmap0 = Color(0xFFEBEDF0);
  static const heatmap1 = Color(0xFFDCFCE7);
  static const heatmap2 = Color(0xFF86EFAC);
  static const heatmap3 = Color(0xFF22C55E);
  static const heatmap4 = Color(0xFF16A34A);

  // Preset habit colors (user picks one when creating a habit)
  static const habitColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Rose
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];
}

/// Dark palette — keeps the emerald identity but on a deep green-black base.
class HabitForgeDarkColors extends AppColorsBase {
  @override
  Color get primary => const Color(0xFF34D399);
  @override
  Color get primaryLight => const Color(0xFF6EE7B7);
  Color get primaryDark => const Color(0xFF10B981);

  @override
  Color get secondary => const Color(0xFFFBBF24);
  Color get secondaryLight => const Color(0xFFFCD34D);
  Color get secondaryDark => const Color(0xFFF59E0B);

  Color get accent => const Color(0xFF818CF8);
  Color get accentLight => const Color(0xFFA5B4FC);

  @override
  Color get scaffoldBg => const Color(0xFF0F1A12);
  @override
  Color get cardBg => const Color(0xFF1A2E1F);
  @override
  Color get surfaceBg => const Color(0xFF243829);
  Color get surfaceLight => const Color(0xFF243829);

  @override
  Color get textPrimary => const Color(0xFFE6F4EA);
  @override
  Color get textSecondary => const Color(0xFFA8C3AF);
  Color get textTertiary => const Color(0xFF6F8B77);

  @override
  Color get error => const Color(0xFFCF6679);
  @override
  Color get onPrimary => const Color(0xFF0F1A12);
  @override
  Color get onSurface => const Color(0xFFE6F4EA);
}
