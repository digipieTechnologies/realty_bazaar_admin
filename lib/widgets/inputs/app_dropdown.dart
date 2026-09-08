// File: lib/widgets/inputs/app_dropdown.dart
// Purpose: Reusable Dropdown selection input field matching Admin App design system.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/context_ext.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final Widget? icon;
  final bool readOnly;

  const AppDropdown({
    super.key,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    this.icon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: context.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6.0),
        ],
        DropdownButtonFormField<T>(
          value: value,
          onChanged: readOnly ? null : onChanged,
          validator: validator,
          isExpanded: true,
          style: context.titleSmall?.copyWith(color: colorScheme.onSurface),
          icon: icon ?? Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.bodySmall?.copyWith(color: AppColors.slate400, fontSize: 14),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: readOnly ? colorScheme.surfaceContainerLow : colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          items: items,
        ),
      ],
    );
  }
}
