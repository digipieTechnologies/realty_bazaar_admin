import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/property_visits/property_visits_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/toast/app_toast.dart';

class PropertyVisitsScreen extends StatefulWidget {
  const PropertyVisitsScreen({super.key});

  @override
  State<PropertyVisitsScreen> createState() => PropertyVisitsScreenState();
}

class PropertyVisitsScreenState extends State<PropertyVisitsScreen> {
  late PropertyVisitsProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyVisitsProvider>().fetchVisits();
    });
  }

  Future<void> _updateStatus(PropertyVisitModel visit, String newStatus) async {
    final success = await _provider.updateVisitStatus(visit.id, newStatus);
    if (success && mounted) {
      AppToast.showSuccess('Status Updated', 'Visit status changed to $newStatus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    _provider = context.watch<PropertyVisitsProvider>();
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Property Visits'),
        elevation: 0,
        backgroundColor: context.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSearchBar(
              hintText: 'Search by client name…',
              onSearch: _provider.setSearchQuery,
              isMobile: false,
            ),
            const SizedBox(height: 12),
            _buildStatusFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: AppDataTable(
                isLoading: _provider.isLoading,
                columns: const [
                  AppDataColumn(label: 'Client', flex: 2),
                  AppDataColumn(label: 'Property', flex: 2),
                  AppDataColumn(label: 'Broker', flex: 2),
                  AppDataColumn(label: 'Visit Date', flex: 2),
                  AppDataColumn(label: 'Status', flex: 1),
                  AppDataColumn(label: 'Actions', flex: 2),
                ],
                rows: _provider.visits
                    .map((v) => _buildRow(context, v))
                    .toList(),
              ),
            ),
            PaginationWidget(
              pagination: _provider.pagination,
              currentPage: _provider.currentPage,
              totalPages: _provider.totalPages,
              totalCount: _provider.totalCount,
              isLoading: _provider.isLoading,
              onPageChanged: _provider.setPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final statuses = ['All', 'pending', 'confirmed', 'completed', 'cancelled'];
    final current = _provider.filter.status;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final isSelected = s == 'All' ? current == null : current == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s == 'All' ? 'All' : _capitalize(s)),
              selected: isSelected,
              onSelected: (_) {
                _provider.updateFilter(
                  _provider.filter.copyWith(
                    status: s == 'All' ? null : s,
                    clearStatus: s == 'All',
                    page: 1,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  DataRowItem _buildRow(BuildContext context, PropertyVisitModel visit) {
    return DataRowItem(
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(visit.clientName, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
            Text(visit.clientPhone, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        Text(visit.property?.propertyTitle ?? visit.propertyId, style: AppTextStyles.body2, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(visit.broker?.businessName ?? '-', style: AppTextStyles.body2, maxLines: 1, overflow: TextOverflow.ellipsis),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('dd MMM yyyy').format(visit.visitDate), style: AppTextStyles.body2),
            Text(visit.timeSlot, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        _buildStatusChip(visit.status),
        _buildActions(visit),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final (bg, fg) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(_capitalize(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  (Color, Color) _statusColors(String status) => switch (status) {
        'confirmed' => (AppColors.successLight, AppColors.success),
        'completed' => (AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
        'cancelled' => (AppColors.errorLight, AppColors.error),
        _ => (AppColors.warningLight, AppColors.warning),
      };

  Widget _buildActions(PropertyVisitModel visit) {
    if (visit.isCompleted || visit.isCancelled) {
      return Text(_capitalize(visit.status), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 4,
      children: [
        if (visit.isPending)
          _actionBtn('Confirm', AppColors.success, () => _updateStatus(visit, 'confirmed')),
        if (!visit.isCompleted && !visit.isCancelled)
          _actionBtn('Complete', AppColors.primary, () => _updateStatus(visit, 'completed')),
        if (!visit.isCancelled)
          _actionBtn('Cancel', AppColors.error, () => _updateStatus(visit, 'cancelled')),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
