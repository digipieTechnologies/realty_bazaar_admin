// File: lib/modules/leads/screens/leads_desktop.dart
// Purpose: Super Admin desktop table view for social leads with Enterprise filter toolbar, quick filters, sidebar filter panel, pagination, and action menus.

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/widgets/common/cached_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_platform_badge.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/lead_filter_model.dart';
import '../widgets/add_lead_dialog.dart';
import '../widgets/reassign_broker_dialog.dart';
import 'leads_screen.dart';

class LeadsDesktop extends StatelessWidget {
  final LeadsScreenState state;

  const LeadsDesktop({super.key, required this.state});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  Future<void> _confirmDelete(BuildContext context, SocialLeadModel lead) async {
    final confirmed = await ConfirmDialog.showResponsive(
      context: context,
      title: 'leads_delete_lead'.tr(),
      message: 'leads_delete_confirm_msg'.tr(),
      confirmLabel: 'delete'.tr(),
      cancelLabel: 'cancel'.tr(),
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<AdminLeadsProvider>().deleteLead(lead.id!);
      if (success && context.mounted) {
        AppToast.showSuccess('leads_toast_deleted'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = state.leadsProv;
    final leads = provider.leads;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar with Filter Toggle & Add Button ──────────────────────
          AppSearchBar(
            hintText: 'leads_search_hint'.tr(),
            onSearch: (query) => state.filterProvider.updateSearch(query),
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            activeFilterCount: state.filterProvider.activeFiltersCount,
            addLabel: 'leads_add_lead'.tr(),
            onAdd: () => AddLeadDialog.show(context),
          ),
          const SizedBox(height: 8),

          // ── Enterprise Quick Filters ────────────────────────────────────────
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: LeadFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),
          const SizedBox(height: 8),

          // ── Data Table & Enterprise Filter Sidebar ──────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AppDataTable(
                          isLoading: provider.isLoading,
                          emptyMessage: 'leads_empty_title'.tr(),
                          columns: [
                            AppDataColumn(label: 'leads_col_client'.tr(), flex: 2),
                            AppDataColumn(label: 'leads_col_broker'.tr(), flex: 4),
                            AppDataColumn(label: 'leads_col_platform'.tr(), flex: 1),
                            AppDataColumn(label: 'leads_col_property'.tr(), flex: 3),
                            AppDataColumn(label: 'leads_col_date'.tr(), flex: 1),
                            AppDataColumn(label: 'leads_col_actions'.tr(), flex: 1),
                          ],
                          rows: leads.map((lead) => _buildRow(context, lead)).toList(),
                        ),
                      ),
                      PaginationWidget(
                        pagination: provider.pagination,
                        currentPage: provider.currentPage,
                        totalPages: provider.totalPages,
                        totalCount: provider.totalItems,
                        isLoading: provider.isLoading,
                        onPageChanged: (page) => provider.setPage(page),
                      ),
                    ],
                  ),
                ),
                if (state.showFilterSidebar) ...[
                  const SizedBox(width: 16),
                  EnterpriseFilterPanel(
                    provider: state.filterProvider,
                    isSidebar: true,
                    onClose: state.toggleFilterSidebar,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(BuildContext context, SocialLeadModel lead) {
    final brokerName = lead.broker?.businessName ?? 'leads_unassigned'.tr();
    final hasBroker = lead.broker != null;

    final rawPropertyTitle = lead.socialPost?.property?.propertyTitle;
    final propertyDisplay = (rawPropertyTitle != null && rawPropertyTitle.trim().isNotEmpty)
        ? rawPropertyTitle.trim()
        : (lead.propertyDetails?.trim().isNotEmpty == true
              ? lead.propertyDetails!.trim()
              : (lead.socialPost?.caption ?? 'leads_general_inquiry'.tr()));

    return DataRowItem(
      onTap: () => context.go('${AppRoutes.socialLeads}/detail/${lead.id}', extra: lead),
      cells: [
        // 1. Client Prospect (Avatar, Name, Phone)
        Row(
          children: [
            CachedImageInitials(
              imageUrl: "",
              initials: lead.userName.forImage,
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lead.userName.isNotEmpty ? lead.userName : 'leads_prospect_fallback'.tr(),
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.contactNumber,
                    style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        // 2. Assigned Broker Pill
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: hasBroker ? AppColors.secondaryLight : context.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasBroker ? AppColors.secondary.withValues(alpha: 0.2) : context.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 14,
                  color: hasBroker ? AppColors.secondary : context.textColorMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    brokerName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasBroker ? AppColors.secondary : context.textColorMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Platform Source Badge
        Align(
          alignment: Alignment.centerLeft,
          child: AppPlatformBadge(platform: lead.socialPost?.platform),
        ),

        // 4. Inquired Property Title
        DataCellText(text: propertyDisplay),

        // 5. Received Date
        DataCellText(text: _formatDate(lead.createdAt)),

        // 6. Actions Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DataCellActions(
              onView: () => context.go('${AppRoutes.socialLeads}/detail/${lead.id}', extra: lead),
              onEdit: () => AddLeadDialog.show(context, leadToEdit: lead),
              onDelete: () => _confirmDelete(context, lead),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              tooltip: 'leads_reassign_broker'.tr(),
              color: context.colorScheme.secondary,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: () => ReassignBrokerDialog.show(context, lead),
            ),
          ],
        ),
      ],
    );
  }
}
