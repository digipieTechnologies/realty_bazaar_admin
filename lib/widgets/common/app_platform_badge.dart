import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppPlatformBadge extends StatelessWidget {
  final String? platform;
  final bool isHeaderStyle;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const AppPlatformBadge({
    super.key,
    required this.platform,
    this.isHeaderStyle = false,
    this.iconSize = 14.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final lower = platform?.toLowerCase() ?? '';
    final isFacebook = lower == 'facebook';
    final isInstagram = lower == 'instagram';

    final Color brandColor = isFacebook
        ? AppColors.facebook
        : (isInstagram ? AppColors.instagram : AppColors.primary);

    final IconData brandIcon = isFacebook
        ? Icons.facebook_rounded
        : (isInstagram ? Icons.camera_alt_rounded : Icons.public_rounded);

    final String labelText = isFacebook
        ? 'Facebook'
        : (isInstagram ? 'Instagram' : (platform?.isNotEmpty == true ? platform! : 'leads_direct'.tr()));

    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);

    if (isHeaderStyle) {
      return Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(brandIcon, size: iconSize, color: brandColor),
            const SizedBox(width: 6.0),
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: brandColor.withValues(alpha: 0.2), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(brandIcon, size: iconSize, color: brandColor),
          const SizedBox(width: 6.0),
          Text(
            labelText,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: brandColor),
          ),
        ],
      ),
    );
  }
}
