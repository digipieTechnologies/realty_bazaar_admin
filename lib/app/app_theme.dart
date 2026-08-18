// File: lib/app/app_theme.dart
// Purpose: Main Theme definitions for the Super Admin application.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        errorContainer: AppColors.errorLight,
        onPrimary: AppColors.surface,
        onSecondary: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        onError: AppColors.surface,
        outlineVariant: AppColors.border,
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1.0, space: 1.0),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body1,
        bodyMedium: AppTextStyles.body2,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
      ),

      // Input Decoration Theme (matching travel_agenies 12px/8px radius & borders)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.label,
        errorStyle: AppTextStyles.error,
        prefixIconColor: AppColors.iconDefault,
        suffixIconColor: AppColors.iconDefault,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Card Theme (12px radius, clean elevation matching travel_agenies)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),

      // Dialog Theme (16px radius matching travel_agenies)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      ),

      // Button Theme
      buttonTheme: const ButtonThemeData(buttonColor: AppColors.primary, textTheme: ButtonTextTheme.primary),

      // AppBar Theme (matching travel_agenies)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0.0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22.0),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary, size: 22.0),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
