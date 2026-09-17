// File: lib/widgets/inputs/app_textfield.dart
// Purpose: Form input field with password toggles, validation styling, and state preservation.

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../app/app_colors.dart';

/// Reusable text field for auth screens.
/// Supports both dashboard theme-aware styling and EstateFlow auth styling.
/// Use [useAuthStyle] = true for EstateFlow auth screens.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;
  final Color? fillColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final int? maxLength;
  final String? initialValue;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
    this.fillColor,
    this.onTap,
    this.contentPadding,
    this.maxLength,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textField = Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (readOnly &&
            onTap != null &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space) {
          onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextFormField(
        initialValue: initialValue,
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        keyboardType: readOnly ? TextInputType.none : keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged,
        readOnly: readOnly,
        showCursor: !readOnly,
        enableInteractiveSelection: !readOnly,
        enabled: enabled,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        minLines: obscureText ? 1 : minLines,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
        cursorColor: colorScheme.primary,
        style: context.titleSmall?.copyWith(color: colorScheme.onSurface),
        onTapOutside: (p0) {
          focusNode?.unfocus();
        },
        onTap: onTap,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        decoration: _defaultDecoration(context, colorScheme, isDark),
      ),
    );

    final bool isMultiline = maxLines == null || maxLines! > 1;
    final Widget fieldWidget = isMultiline
        ? Stack(
            children: [
              textField,
              Positioned(
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(10, 10),
                    painter: ResizeHandlePainter(color: isDark ? Colors.grey[600]! : AppColors.slate300),
                  ),
                ),
              ),
            ],
          )
        : textField;

    if (label == null || label?.removeSpaces().isEmpty == true) return fieldWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: context.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        fieldWidget,
      ],
    );
  }

  /// Default dashboard decoration — clean white/surface fill with thin border
  InputDecoration _defaultDecoration(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: context.bodySmall?.copyWith(
        color: isDark ? colorScheme.onSurfaceVariant : AppColors.slate400,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? colorScheme.surface,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorStyle: context.bodySmall?.copyWith(color: colorScheme.error, fontSize: 12),
    );
  }
}

class KeyboardHelper {
  static const MethodChannel _channel = MethodChannel('keyboard_helper');

  static Future<void> showKeyboard() async {
    if (!UniversalPlatform.isMobile) return;
    try {
      await _channel.invokeMethod('showKeyboard');
    } catch (e) {
      debugPrint("Failed to open keyboard: ${e.toString()}");
    }
  }

  static Future<void> hideKeyboard(BuildContext context) async {
    if (!UniversalPlatform.isMobile) return;
    try {
      await _channel.invokeMethod('hideKeyboard');
      if (context.mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Failed to hide keyboard: ${e.toString()}");
    }
  }
}

class ResizeHandlePainter extends CustomPainter {
  final Color color;

  ResizeHandlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width - 10, size.height), Offset(size.width, size.height - 10), paint);
    canvas.drawLine(Offset(size.width - 6, size.height), Offset(size.width, size.height - 6), paint);
    canvas.drawLine(Offset(size.width - 2, size.height), Offset(size.width, size.height - 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
