// File: lib/app/app_colors.dart
// Purpose: Design system color tokens mirroring brokerflow-app.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette (Indigo based for professional modern trust)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700

  // Secondary Palette (Teal based for accents & dynamic highlights)
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color secondaryLight = Color(0xFFF0FDFA); // Teal 50
  static const Color secondaryDark = Color(0xFF0F766E); // Teal 700

  // Neutral Palette (Backgrounds, Surfaces, Borders from travel_agenies)
  static const Color background = Color(0xFFF1F4F9); // Light background (#F1F4F9)
  static const Color surface = Color(0xFFFFFFFF); // Surface / Card white
  static const Color surfaceLight = Color(0xFFE1E2EC); // Muted input background (#E1E2EC)
  static const Color border = Color(0xFFC2C6CF); // Border (#C2C6CF)
  static const Color divider = Color(0xFFE1E2EC); // Muted divider (#E1E2EC)

  // Text Colors (from travel_agenies)
  static const Color textPrimary = Color(0xFF0B1F33); // Foreground (#0B1F33)
  static const Color textSecondary = Color(0xFF535F70); // Muted foreground (#535F70)
  static const Color textMuted = Color(0xFF73777F); // Muted / Hint (#73777F)

  // Icon Colors
  static const Color iconDefault = Color(0xFF535F70); // Icon color (#535F70)

  // Status & Feedback Colors (from travel_agenies)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorLight = Color(0xFFFEE2E2); // Red container / light

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 50

  static const Color info = Color(0xFF2563EB); // Blue 600
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // Shimmer Effects
  static const Color shimmerBase = Color(0xFFE1E2EC);
  static const Color shimmerHighlight = Color(0xFFF1F4F9);

  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);

  // Gradients
  static const List<Color> primaryGradient = [primary, primaryDark];

  static const List<Color> secondaryGradient = [secondary, secondaryDark];

  static const List<Color> glassGradient = [Color(0x33FFFFFF), Color(0x0FFFFFFF)];
}
