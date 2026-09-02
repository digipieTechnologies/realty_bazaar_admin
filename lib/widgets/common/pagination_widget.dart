import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/network/pagination_model.dart';

/// Reusable pagination widget for admin list screens
class PaginationWidget extends StatelessWidget {
  final PaginationMetadata? pagination;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final bool isLoading;

  const PaginationWidget({
    super.key,
    this.pagination,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effTotalPages = (pagination?.totalPages ?? totalPages).clamp(1, 999999);
    final effPage = (pagination?.page ?? currentPage).clamp(1, effTotalPages);
    final effTotal = pagination?.total ?? totalCount;
    final pageSize = pagination?.pageSize ?? 10;

    // Do not show pagination if total pages is 1 or total items is <= page size
    if (effTotalPages <= 1 || effTotal <= pageSize) {
      return const SizedBox.shrink();
    }

    final startItem = effTotal == 0 ? 0 : ((effPage - 1) * pageSize) + 1;
    final endItem = (effPage * pageSize).clamp(0, effTotal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: (effPage > 1 && !isLoading) ? () => onPageChanged(effPage - 1) : null,
              tooltip: 'common_previous_page'.tr(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            _buildPageNumbers(context, effPage, effTotalPages, colorScheme, isMobile: isMobile),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: (effPage < effTotalPages && !isLoading) ? () => onPageChanged(effPage + 1) : null,
              tooltip: 'common_next_page'.tr(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 4),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Showing $startItem-$endItem of $effTotal items',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: controls),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing $startItem-$endItem of $effTotal items',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    controls,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPageNumbers(
    BuildContext context,
    int currentPage,
    int totalPages,
    ColorScheme colorScheme, {
    bool isMobile = false,
  }) {
    List<Widget> pageWidgets = [];

    // Simple view when pages count is small or responsive fallback
    List<int> pagesToDisplay = [];
    if (totalPages <= 5) {
      pagesToDisplay = List.generate(totalPages, (i) => i + 1);
    } else {
      pagesToDisplay.add(1);
      if (currentPage > 3) {
        pagesToDisplay.add(-1); // ellipsis
      }
      for (
        int i = (currentPage - 1).clamp(2, totalPages - 1);
        i <= (currentPage + 1).clamp(2, totalPages - 1);
        i++
      ) {
        if (!pagesToDisplay.contains(i)) {
          pagesToDisplay.add(i);
        }
      }
      if (currentPage < totalPages - 2) {
        pagesToDisplay.add(-2); // ellipsis
      }
      if (!pagesToDisplay.contains(totalPages)) {
        pagesToDisplay.add(totalPages);
      }
    }

    for (int page in pagesToDisplay) {
      if (page < 0) {
        pageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
        );
      } else {
        final isSelected = page == currentPage;
        pageWidgets.add(
          InkWell(
            onTap: (isSelected || isLoading) ? null : () => onPageChanged(page),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Row(children: pageWidgets);
  }
}
