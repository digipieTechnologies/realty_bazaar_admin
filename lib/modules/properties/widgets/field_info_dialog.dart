// File: lib/modules/properties/widgets/field_info_dialog.dart
// Purpose: Field info dialog for guidance, good examples, and tips.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';

class FieldInfoDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<String> examples;
  final String? tip;

  const FieldInfoDialog({
    super.key,
    required this.title,
    required this.description,
    this.examples = const [],
    this.tip,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    List<String> examples = const [],
    String? tip,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          FieldInfoDialog(title: title, description: description, examples: examples, tip: tip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      actions: [
        AppButton(
          title: 'got_it'.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary, height: 1.5)),
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              Text(
                'Good Examples:',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: examples
                      .map(
                        (ex) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  ex,
                                  style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (tip != null && tip!.isNotEmpty) ...[
              const SizedBox(height: 14.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 18.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Pro Tip: $tip',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
