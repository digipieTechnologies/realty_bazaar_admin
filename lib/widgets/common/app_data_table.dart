import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Column definition for AppDataTable
class AppDataColumn {
  final String label;
  final double? flex;
  final bool numeric;

  const AppDataColumn({required this.label, this.flex, this.numeric = false});
}

/// Row data for AppDataTable
class DataRowItem {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const DataRowItem({required this.cells, this.onTap});
}

/// Responsive data table with header and scrollable content
class AppDataTable<T> extends StatelessWidget {
  final List<AppDataColumn> columns;
  final List<DataRowItem> rows;
  final bool isLoading;
  final String? emptyMessage;

  /// Minimum width required to show all columns beautifully without squishing.
  /// Calculated dynamically if not provided.
  final double? minWidth;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyMessage,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ScrollController horizontalScrollController = ScrollController();

    final double calculatedMinWidth = minWidth ?? (columns.length * 150.0).clamp(600.0, 1400.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool shouldScrollHorizontally = constraints.maxWidth < calculatedMinWidth;
          final double tableWidth = shouldScrollHorizontally ? calculatedMinWidth : constraints.maxWidth;

          return Scrollbar(
            thumbVisibility: true,
            controller: horizontalScrollController,
            child: SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: shouldScrollHorizontally
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    _buildHeader(context, colorScheme),
                    const Divider(height: 1),
                    Flexible(
                      child: isLoading
                          ? _buildLoading(context)
                          : rows.isEmpty
                          ? _buildEmpty(context, colorScheme)
                          : _buildRows(context, colorScheme),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: columns.map((col) {
          return Expanded(
            flex: col.flex?.toInt() ?? 1,
            child: Text(
              col.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: col.numeric ? TextAlign.end : TextAlign.start,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRows(BuildContext context, ColorScheme colorScheme) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: rows.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
      itemBuilder: (context, index) {
        final row = rows[index];
        return InkWell(
          onTap: row.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: List.generate(row.cells.length, (i) {
                return Expanded(flex: columns[i].flex?.toInt() ?? 1, child: row.cells[i]);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          emptyMessage ?? 'no_data'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Text cell with ellipsis and tooltip for long text
class DataCellText extends StatelessWidget {
  final String text;
  final bool numeric;
  final TextStyle? style;

  const DataCellText({super.key, required this.text, this.numeric = false, this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        textAlign: numeric ? TextAlign.end : TextAlign.start,
      ),
    );
  }
}

/// Actions cell with view, edit, and delete buttons
class DataCellActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final bool isMobile;

  const DataCellActions({super.key, this.onEdit, this.onDelete, this.onView, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      spacing: isMobile ? 0 : 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onView != null)
          IconButton(
            icon: Icon(Icons.visibility_outlined, size: 20, color: colorScheme.primary),
            onPressed: onView,
            tooltip: 'View'.tr(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
            onPressed: onEdit,
            tooltip: 'Edit'.tr(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            onPressed: onDelete,
            tooltip: 'Delete'.tr(),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
      ],
    );
  }
}
