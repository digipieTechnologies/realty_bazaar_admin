// File: lib/widgets/dialogs/app_dialog.dart
// Purpose: Base pop-up dialog container mirroring brokerflow-app styling.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final bool hasCloseIcon;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.hasCloseIcon = true,
  });

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    bool isDanger = true,
    bool hasCloseIcon = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        hasCloseIcon: hasCloseIcon,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: (isDanger ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    color: isDanger ? AppColors.error : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppButton.outline(text: cancelLabel, onPressed: () => Navigator.of(context).pop(false)),
          const SizedBox(width: 12),
          AppButton.solid(
            text: confirmLabel,
            color: isDanger ? AppColors.error : AppColors.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 16.0, top: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Visibility.maintain(
                    visible: hasCloseIcon,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: content),
                    if (actions != null && actions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
