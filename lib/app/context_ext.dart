// File: lib/app/context_ext.dart
// Purpose: BuildContext extensions for dynamic theme tokens, responsive breakpoints, and navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

extension AppContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  bool get isLight => theme.brightness == Brightness.light;

  bool get isDark => !isLight;

  TextTheme get textTheme => theme.textTheme;

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME-AWARE DYNAMIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary brand color from theme
  Color get primaryColor => colorScheme.primary;

  /// On-primary color for text/icons on primary backgrounds
  Color get onPrimaryColor => colorScheme.onPrimary;

  /// Primary container color
  Color get primaryContainerColor => colorScheme.primaryContainer;

  Color get secondaryContainerColor => colorScheme.secondaryContainer;

  /// Secondary brand color
  Color get secondaryColor => colorScheme.secondary;

  /// Background / scaffold canvas color
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// Surface / card color
  Color get surfaceColor => colorScheme.surface;

  /// Elevated surface color (dialogs, popovers, dropdowns)
  Color get surfaceElevatedColor => isDark ? const Color(0xFF1C2A44) : Colors.white;

  /// Muted / light surface color (input fill, metric chips, unselected states)
  Color get surfaceLightColor => isDark ? const Color(0xFF1C2A44) : const Color(0xFFF1F5F9);

  /// On-surface color for text on surface
  Color get onSurfaceColor => colorScheme.onSurface;

  /// Primary text color
  Color get textColor => colorScheme.onSurface;

  /// Secondary text color
  Color get textColorMuted => colorScheme.onSurfaceVariant;

  /// Text secondary color alias
  Color get textSecondaryColor => colorScheme.onSurfaceVariant;

  /// Muted foreground alias
  Color get mutedForegroundColor => colorScheme.onSurfaceVariant;

  /// Inverse text color
  Color get inverseTextColor => colorScheme.inverseSurface;

  /// Global border color
  Color get borderColor => colorScheme.outlineVariant;

  /// Divider color
  Color get dividerColor => theme.dividerTheme.color ?? borderColor;

  /// Shadow color
  Color get shadowColor => colorScheme.shadow;

  /// Card color alias
  Color get cardColor => colorScheme.surface;

  /// Default icon color
  Color get iconColor => colorScheme.onSurfaceVariant;

  /// Active icon color
  Color get iconActiveColor => colorScheme.primary;

  /// Suffix / prefix icon color for inputs
  Color get suffixIconColor => colorScheme.onSurfaceVariant;

  /// Hint text color
  Color get hintColor => colorScheme.onSurfaceVariant;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS & FEEDBACK DYNAMIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Success color
  Color get successColor => const Color(0xFF10B981);

  /// Success container / light background
  Color get successContainerColor => isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);

  /// Success border
  Color get successBorderColor => isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);

  /// Warning color
  Color get warningColor => const Color(0xFFF59E0B);

  /// Warning container / light background
  Color get warningContainerColor => isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);

  /// Warning border
  Color get warningBorderColor => isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);

  /// Error color
  Color get errorColor => colorScheme.error;

  /// Error container / light background
  Color get errorContainerColor => colorScheme.errorContainer;

  /// Error border
  Color get errorBorderColor => isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);

  /// Info color
  Color get infoColor => colorScheme.primary;

  /// Info container / light background
  Color get infoContainerColor => isDark ? const Color(0xFF0F325E) : const Color(0xFFEAF3FF);

  /// Shimmer base color
  Color get shimmerBaseColor => isDark ? const Color(0xFF1C2A44) : const Color(0xFFE2E8F0);

  /// Shimmer highlight color
  Color get shimmerHighlightColor => isDark ? const Color(0xFF233554) : const Color(0xFFF8FAFC);

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COLOR ACCESSORS (for backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  @Deprecated('Use textColorMuted instead')
  Color get labelGrey => colorScheme.onSurfaceVariant;

  @Deprecated('Use textColorMuted instead')
  Color get greyColor => colorScheme.onSurfaceVariant;

  @Deprecated('Use textColorMuted instead')
  Color? get lightGreyColor => colorScheme.onSurfaceVariant;

  @Deprecated('Use textColor instead')
  Color? get lightTitleTextColor => colorScheme.onSurface;

  @Deprecated('Use textColorMuted instead')
  Color? get lightLabelTextColor => colorScheme.onSurfaceVariant;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT STYLES - Inheriting colors from theme
  // ═══════════════════════════════════════════════════════════════════════════

  TextStyle? get labelMedium => textTheme.labelMedium;

  TextStyle? get labelMediumBold => textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get labelSmall => textTheme.labelSmall;

  TextStyle? get labelSmallBold => textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get labelExtraSmall => textTheme.labelSmall?.copyWith(fontSize: 12);

  TextStyle? get labelLarge => textTheme.labelLarge;

  TextStyle? get labelLargeBold => textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get titleExtraSmall => textTheme.titleSmall?.copyWith(fontSize: 13);

  TextStyle? get title12 => textTheme.titleSmall?.copyWith(fontSize: 12);

  TextStyle? get title12SmallBold =>
      textTheme.titleSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.bold);

  TextStyle? get titleExtraSmallBold =>
      textTheme.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.bold);

  TextStyle? get titleSmall => textTheme.titleSmall;

  TextStyle? get titleSmallBold => textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get body13Small => textTheme.bodySmall?.copyWith(fontSize: 13);

  TextStyle? get body13SmallBold => textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.bold);

  TextStyle? get bodyExtraSmall => textTheme.bodySmall?.copyWith(fontSize: 12);

  TextStyle? get bodySmall => textTheme.bodySmall;

  TextStyle? get bodySmallBold => textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get bodyMedium => textTheme.bodyMedium;

  TextStyle? get bodyMediumBold => textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get body15 => bodyMedium?.copyWith(fontSize: 15);

  TextStyle? get body15Bold => body15?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get body16 => bodyMedium?.copyWith(fontSize: 16);

  TextStyle? get body16Bold => body16?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get titleMedium => textTheme.titleMedium;

  TextStyle? get titleMediumBold => textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get titleLarge => textTheme.titleLarge;

  TextStyle? get titleLargeBold => textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get titleLargeExtraBold => textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900);

  TextStyle? get title14 => textTheme.titleMedium?.copyWith(fontSize: 14);

  TextStyle? get title15 => textTheme.titleMedium?.copyWith(fontSize: 15);

  TextStyle? get title16 => textTheme.titleMedium?.copyWith(fontSize: 16);

  TextStyle? get title18 => textTheme.titleMedium?.copyWith(fontSize: 18);

  TextStyle? get title20 => textTheme.titleMedium?.copyWith(fontSize: 20);

  TextStyle? get title16Bold => textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold);

  TextStyle? get title15Bold => textTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold);

  TextStyle? get labelTitleStyle => title15?.copyWith(fontSize: 18, fontWeight: FontWeight.w700);

  TextStyle? get label15 => textTheme.labelMedium?.copyWith(fontSize: 15);

  TextStyle? get label16 => textTheme.labelMedium?.copyWith(fontSize: 16);

  TextStyle? get label15Bold => textTheme.labelMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.bold);

  /// Button text style - uses onPrimary for filled buttons
  TextStyle? get filledButtonPrimary =>
      label15?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: onPrimaryColor);

  TextStyle? get headlineSmall => textTheme.headlineSmall;

  TextStyle? get headlineSmallBold => textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get headlineMedium => textTheme.headlineMedium;

  TextStyle? get headlineMediumBold => textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);

  TextStyle? get headlineLarge => textTheme.headlineLarge;

  TextStyle? get headlineLargeBold => textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold);

  /// Hint text style - uses muted foreground color
  TextStyle? get hintStyle => textTheme.bodySmall?.copyWith(color: hintColor);

  TextStyle? get hintStyle2 => textTheme.bodySmall?.copyWith(color: textColorMuted);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC TEXT STYLES — dynamically resolving colors from theme
  // ═══════════════════════════════════════════════════════════════════════════

  /// Page title — "Add New Lead", "Welcome back, John"
  TextStyle get pageTitle => TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Page title for mobile (slightly smaller)
  TextStyle get pageTitleMobile =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Page subtitle
  TextStyle get pageSubtitle =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: mutedForegroundColor);

  /// Section title — "Recent Leads", "Buyer Requirement Details"
  TextStyle get sectionTitle => TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Card title — lead name, property title
  TextStyle get cardTitle => TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceColor);

  /// Card subtitle — code, city, date
  TextStyle get cardSubtitle =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: mutedForegroundColor);

  /// Badge text — status badges, tags
  TextStyle get badgeText => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurfaceColor);

  /// Sidebar / drawer nav item label
  TextStyle get navLabel => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurfaceColor);

  /// Button text — filled buttons, outlined buttons
  TextStyle get buttonLabel => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  /// Dialog title
  TextStyle get dialogTitle => TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Dialog body text
  TextStyle get dialogBody =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: mutedForegroundColor, height: 1.5);

  /// App bar profile name text
  TextStyle get appBarTitle => TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: onSurfaceColor);

  /// Input hint text
  TextStyle get inputHint =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: mutedForegroundColor);

  /// Small muted text (11px) — dates, time ago
  TextStyle get smallMuted =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: mutedForegroundColor);

  /// Brand header title — sidebar app name
  TextStyle get brandTitle =>
      TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurfaceColor, height: 1.2);

  /// Brand header subtitle — "Broker Portal"
  TextStyle get brandSubtitle =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: mutedForegroundColor);

  /// Tab toggle label
  TextStyle get tabLabel => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  /// Stat card value (large number)
  TextStyle get statValue => TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Stat card title (small label)
  TextStyle get statLabel =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mutedForegroundColor);

  /// Form field label
  TextStyle get fieldLabel => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurfaceColor);

  /// Form field value/input text
  TextStyle get fieldValue => TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceColor);

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  MediaQueryData get mq => MediaQuery.of(this);

  bool get isLandscape => mq.orientation == Orientation.landscape;

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
    FocusScope.of(this).requestFocus(FocusNode());
  }

  void pushAndRemoveUntil(String path) {
    while (GoRouter.of(this).canPop() == true) {
      GoRouter.of(this).pop();
    }
    pushReplacement(path);
  }

  DeviceScreenType get deviceType => getDeviceType(MediaQuery.of(this).size);

  bool get isMobile => deviceType == DeviceScreenType.mobile;

  bool get isTablet => deviceType == DeviceScreenType.tablet;

  bool get isDesktop => deviceType == DeviceScreenType.desktop;

  bool get isTrueMobile => isMobile || isTablet || UniversalPlatform.isMobile;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  double get noDataWidth => width > 700 ? width * 0.8 : width - 40;

  double get dialogWidth => width >= 500 ? 500 : width;
}
