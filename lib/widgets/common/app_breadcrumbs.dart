// File: lib/widgets/common/app_breadcrumbs.dart
// Purpose: Reusable Web & Desktop Breadcrumbs Navigation Widget.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/context_ext.dart';

class BreadcrumbItem {
  final String label;
  final String? route;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.route, this.onTap});
}

/// Reusable Web & Desktop Breadcrumbs Navigation Widget.
class AppBreadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final EdgeInsetsGeometry padding;

  const AppBreadcrumbs({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop || items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500);

    final activeColor = colorScheme.primary;
    final inactiveColor =
        baseStyle?.color ??
        (isDark ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface.withOpacity(0.8));

    return Padding(
      padding: padding,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: inactiveColor),
              ),
            _buildItem(
              context: context,
              item: items[i],
              isLast: i == items.length - 1,
              baseStyle: baseStyle,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required BreadcrumbItem item,
    required bool isLast,
    required TextStyle? baseStyle,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    if (isLast) {
      return Text(
        item.label.trim(),
        style: baseStyle?.copyWith(color: activeColor, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final isClickable = item.route != null || item.onTap != null;

    final child = Text(
      item.label.trim(),
      style: baseStyle?.copyWith(color: inactiveColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!isClickable) return child;

    return InkWell(
      onTap: () {
        if (item.onTap != null) {
          item.onTap!();
        } else if (item.route != null) {
          context.go(item.route!);
        }
      },
      hoverColor: activeColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0), child: child),
    );
  }
}
