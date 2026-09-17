// File: lib/widgets/dialogs/confirm_dialog.dart
// Purpose: Confirmation dialog (Desktop AlertDialog & Mobile BottomSheet) copied from travel agency app.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/context_ext.dart';

/// Confirmation dialog for delete and sensitive operations on Desktop
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = true,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  static Future<bool?> showResponsive({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) {
    if (context.isDesktop) {
      return show(
        context: context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      );
    } else {
      return ConfirmBottomSheet.show(
        context: context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title, style: context.dialogTitle),
      content: Text(message, style: context.dialogBody),
      backgroundColor: colorScheme.surface,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          child: Text(cancelLabel ?? 'cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel ?? 'confirm'.tr()),
        ),
      ],
    );
  }
}

/// Bottom sheet confirmation for mobile form factor
class ConfirmBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  const ConfirmBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = true,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => ConfirmBottomSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                    style: OutlinedButton.styleFrom(fixedSize: const Size.fromHeight(48)),
                    child: Text(cancelLabel ?? 'cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDestructive ? colorScheme.error : null,
                      foregroundColor: isDestructive ? colorScheme.onError : null,
                      fixedSize: const Size.fromHeight(48),
                    ),
                    child: Text(confirmLabel ?? 'confirm'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
