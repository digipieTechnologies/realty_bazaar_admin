// File: lib/widgets/common/tab_header.dart
// Purpose: Reusable Tab Header component displaying titles, counts, refresh buttons, and action buttons.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TabHeader extends StatelessWidget {
  final String? title;
  final int? count;
  final String? countZeroKey;
  final String? countOneKey;
  final String? countOtherKey;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRefresh;
  final IconData actionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? secondaryActionIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const TabHeader({
    super.key,
    this.title,
    this.count,
    this.countZeroKey,
    this.countOneKey,
    this.countOtherKey,
    this.actionLabel,
    this.onAction,
    this.onRefresh,
    this.actionIcon = Icons.add,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionIcon,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String resolvedTitle = '';
    if (count != null) {
      if (count == 0 && countZeroKey != null) {
        resolvedTitle = countZeroKey!.tr();
      } else if (count == 1 && countOneKey != null) {
        resolvedTitle = countOneKey!.tr();
      } else if (countOtherKey != null) {
        resolvedTitle = countOtherKey!.tr(namedArgs: {'count': count.toString()});
      } else {
        resolvedTitle = title ?? '';
      }
    } else {
      resolvedTitle = title ?? '';
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              resolvedTitle,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (onRefresh != null) ...[
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'common.refresh'.tr(),
            ),
          ],
          if (trailing != null) ...[
            trailing!,
            if (actionLabel != null && onAction != null) const SizedBox(width: 8),
          ] else if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            OutlinedButton.icon(
              onPressed: onSecondaryAction,
              icon: secondaryActionIcon != null
                  ? Icon(secondaryActionIcon, size: 16)
                  : const SizedBox.shrink(),
              label: Text(secondaryActionLabel!),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            if (actionLabel != null && onAction != null) const SizedBox(width: 8),
          ],
          if (actionLabel != null && onAction != null)
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 16),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
