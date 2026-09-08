// File: lib/widgets/inputs/app_date_field.dart
// Purpose: Reusable, theme-aware date & date-time input picker matching AppTextField design styling.

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_colors.dart';

/// Reusable date and date-time input field that matches the styling, borders,
/// labels, and theme awareness of [AppTextField].
class AppDateField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final DateFormat? dateFormat;
  final bool pickTime;
  final bool enabled;
  final bool showClearButton;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final FormFieldValidator<DateTime>? validator;
  final AutovalidateMode? autovalidateMode;

  const AppDateField({
    super.key,
    this.label,
    this.hintText,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.dateFormat,
    this.pickTime = false,
    this.enabled = true,
    this.showClearButton = false,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.contentPadding,
    this.validator,
    this.autovalidateMode,
  });

  Future<void> _handleTap(BuildContext context, FormFieldState<DateTime> state) async {
    if (!enabled) return;

    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);

    DateTime defaultInitDate = value ?? initialDate ?? now;
    if (defaultInitDate.isBefore(effectiveFirstDate)) {
      defaultInitDate = effectiveFirstDate;
    } else if (defaultInitDate.isAfter(effectiveLastDate)) {
      defaultInitDate = effectiveLastDate;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: defaultInitDate,
      firstDate: effectiveFirstDate,
      lastDate: effectiveLastDate,
    );

    if (pickedDate == null || !context.mounted) return;

    DateTime finalDateTime = pickedDate;

    if (pickTime) {
      final initialTime = TimeOfDay.fromDateTime(value ?? initialDate ?? now);
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      } else {
        // If user cancelled time picker, retain original date or cancel
        return;
      }
    }

    state.didChange(finalDateTime);
    onChanged?.call(finalDateTime);
  }

  String _formatValue(DateTime dateTime) {
    if (dateFormat != null) {
      return dateFormat!.format(dateTime);
    }
    if (pickTime) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      builder: (state) {
        final hasError = state.hasError;
        final currentValue = state.value ?? value;
        final displayText = currentValue != null ? _formatValue(currentValue) : '';

        final inputDecoration = InputDecoration(
          hintText: hintText ?? (pickTime ? 'Select date & time' : 'Select date'),
          hintStyle: context.bodySmall?.copyWith(
            color: isDark ? colorScheme.onSurfaceVariant : AppColors.slate400,
            fontSize: 14,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon ??
              (showClearButton && currentValue != null && enabled
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        state.didChange(null);
                        onChanged?.call(null);
                      },
                    )
                  : Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.38),
                    )),
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
            borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
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
          errorText: hasError ? state.errorText : null,
          errorStyle: context.bodySmall?.copyWith(color: colorScheme.error, fontSize: 12),
        );

        final fieldWidget = InkWell(
          onTap: enabled ? () => _handleTap(context, state) : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: inputDecoration,
            isEmpty: currentValue == null,
            child: Text(
              displayText,
              style: context.titleSmall?.copyWith(
                color: enabled
                    ? (currentValue != null ? colorScheme.onSurface : (isDark ? colorScheme.onSurfaceVariant : AppColors.slate400))
                    : colorScheme.onSurface.withOpacity(0.38),
              ),
            ),
          ),
        );

        if (label == null || label?.removeSpaces().isEmpty == true) {
          return fieldWidget;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label!,
              style: context.titleSmall?.copyWith(
                color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            fieldWidget,
          ],
        );
      },
    );
  }
}
