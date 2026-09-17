// File: lib/widgets/inputs/app_phone_text_field.dart
// Purpose: Unified phone text field that integrates an inline country flag and dial code prefix.

import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_textfield.dart';

/// Unified phone text field that integrates a premium inline country flag and dial code prefix.
class AppPhoneTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enabled;
  final Color? fillColor;

  const AppPhoneTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppTextField(
      label: label ?? 'Phone Number',
      hintText: hintText ?? 'Enter 10-digit mobile number',
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      fillColor: fillColor,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇮🇳', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '+91',
              style: context.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 22, color: colorScheme.outline.withValues(alpha: 0.3)),
          ],
        ),
      ),
      suffixIcon: Icon(Icons.phone_outlined, color: colorScheme.onSurfaceVariant, size: 20),
    );
  }
}
