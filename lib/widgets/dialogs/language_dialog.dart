// File: lib/widgets/dialogs/language_dialog.dart
// Purpose: Language selector modal dialog mirroring brokerflow-app.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../models/language_model.dart';
import '../../providers/language/language_provider.dart';

class LanguageDialog extends StatelessWidget {
  const LanguageDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentCode = languageProvider.locale.languageCode;

    return Dialog(
      
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        width: 360.0,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'change_language'.tr(),
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ...LanguageModel.supportedLanguages.map((lang) {
              final isSelected = lang.code == currentCode;
              return InkWell(
                onTap: () {
                  context.setLocale(Locale(lang.code));
                  languageProvider.changeLanguage(Locale(lang.code));
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 20.0)),
                      const SizedBox(width: 12.0),
                      Text(
                        '${lang.name} (${lang.nativeName})',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.0),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
