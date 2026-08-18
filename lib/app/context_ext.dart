//path: lib/app/theme/context_ext.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:universal_platform/universal_platform.dart';

extension AppContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  bool get isLight => Theme.of(this).brightness == Brightness.light;

  bool get isDark => !isLight;

  TextTheme get textTheme => theme.textTheme;

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME-AWARE COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary color from theme (--primary)
  Color get primaryColor => colorScheme.primary;

  /// On-primary color for text/icons on primary backgrounds
  Color get onPrimaryColor => colorScheme.onPrimary;

  /// Primary container color (--primary-light)
  Color get primaryContainerColor => colorScheme.primaryContainer;

  /// Secondary color (--secondary)
  Color get secondaryColor => colorScheme.secondary;

  /// Background/scaffold color (--background)
  Color get backgroundColor => colorScheme.surface;

  /// Surface/card color (--card)
  Color get surfaceColor => colorScheme.surface;

  /// On-surface color for text on surface (--foreground / --card-foreground)
  Color get onSurfaceColor => colorScheme.onSurface;

  /// Muted foreground for secondary text (--muted-foreground)
  Color get mutedForegroundColor => colorScheme.onSurfaceVariant;

  /// Error/destructive color (--destructive)
  Color get errorColor => colorScheme.error;

  /// Border color (--border)
  Color get borderColor => colorScheme.outlineVariant;

  /// Shadow color
  Color get shadowColor => colorScheme.shadow;

  /// Card color
  Color get cardColor => colorScheme.surface;

  /// Text color - primary foreground
  Color get textColor => colorScheme.onSurface;

  /// Text color - secondary/muted
  Color get textColorMuted => colorScheme.onSurfaceVariant;

  /// Inverse text color
  Color get inverseTextColor => colorScheme.inverseSurface;

  /// Suffix icon color for inputs
  Color get suffixIconColor => colorScheme.onSurfaceVariant;

  /// Hint text color
  Color get hintColor => colorScheme.onSurfaceVariant;

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
  // TEXT STYLES - All inherit colors from theme
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
  // SEMANTIC TEXT STYLES — named by usage, not size
  // Use these throughout the app for consistency.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Page title — "Add New Lead", "Welcome back, John"
  TextStyle get pageTitle => TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Page title for mobile (slightly smaller)
  TextStyle get pageTitleMobile =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurfaceColor);

  /// Page subtitle — "Create a new buyer requirement..."
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
  TextStyle get buttonLabel => TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

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
  TextStyle get tabLabel => TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

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

  /// Returns same as MediaQuery.of(context)
  MediaQueryData get mq => MediaQuery.of(this);

  /// Returns if Orientation is landscape
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
