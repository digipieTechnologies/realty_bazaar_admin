// File: lib/modules/leads/screens/leads_mobile.dart
// Purpose: Super Admin mobile view for social leads with responsive card layout, search, quick filters, bottom sheet filter, and quick action dialogs.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/social_lead_model.dart';
import '../../../widgets/common/app_lead_status_badge.dart';
import '../../../widgets/common/app_platform_badge.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/lead_filter_model.dart';
import '../widgets/add_lead_dialog.dart';
import 'leads_screen.dart';

class LeadsMobile extends StatelessWidget {
  final LeadsScreenState state;

  const LeadsMobile({super.key, required this.state});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final provider = state.leadsProv;
    final leads = provider.leads;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Search & Filter Bar
            AppSearchBar(
              hintText: 'leads_search_mobile_hint'.tr(),
              onSearch: (val) => state.filterProvider.updateSearch(val),
              isMobile: true,
              onFilter: state.showFilterBottomSheet,
              activeFilterCount: state.filterProvider.activeFiltersCount,
              addLabel: 'leads_add_lead'.tr(),
              onAdd: () => AddLeadDialog.show(context),
            ),
            const SizedBox(height: 8),

            // Enterprise Quick Filters
            EnterpriseQuickFilters(
              provider: state.filterProvider,
              fields: LeadFilterModel.filterDefinition.fields
                  .where((f) => f.type == FilterType.quickFilter)
                  .toList(),
              isMobile: true,
            ),
            const SizedBox(height: 8),

            // Total Leads Header
            Row(
              children: [
                Text(
                  'leads_total_count'.tr(args: [provider.totalItems.toString()]),
                  style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (state.filterProvider.activeFiltersCount > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: Text('leads_reset_filters'.tr()),
                    onPressed: () => state.filterProvider.reset(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Loading / Empty / Cards List
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (leads.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.group_off_rounded, size: 48, color: context.textColorMuted),
                      const SizedBox(height: 12),
                      Text('leads_empty_title'.tr(), style: AppTextStyles.heading3),
                      const SizedBox(height: 4),
                      Text(
                        'leads_empty_subtitle'.tr(),
                        style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  return _buildLeadCard(context, lead);
                },
              ),

            const SizedBox(height: 16),

            // Pagination Footer
            if (provider.totalPages > 1)
              PaginationWidget(
                currentPage: provider.currentPage,
                totalPages: provider.totalPages,
                totalCount: provider.totalItems,
                onPageChanged: (page) => provider.setPage(page),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, SocialLeadModel lead) {
    final brokerName = lead.broker?.businessName ?? 'leads_unassigned'.tr();
    final hasBroker = lead.broker != null;

    final rawPropertyTitle = lead.socialPost?.property?.propertyTitle;
    final propertyDisplay = (rawPropertyTitle != null && rawPropertyTitle.trim().isNotEmpty)
        ? rawPropertyTitle.trim()
        : (lead.propertyDetails?.trim().isNotEmpty == true
            ? lead.propertyDetails!.trim()
            : (lead.socialPost?.caption ?? 'leads_general_inquiry'.tr()));

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => context.go('${AppRoutes.socialLeads}/detail/${lead.id}', extra: lead),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name & Phone, Source Badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        lead.userName.isNotEmpty ? lead.userName[0].toUpperCase() : '?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryColor, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.userName.isNotEmpty ? lead.userName : 'leads_prospect_fallback'.tr(),
                            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lead.contactNumber} • ${_formatDate(lead.createdAt)}',
                            style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLeadStatusBadge(
                          status: lead.status,
                          onStatusChanged: (newStatus) async {
                            final success = await state.leadsProv.updateLeadStatus(lead.id!, newStatus);
                            if (success && context.mounted) {
                              AppToast.showSuccess('leads_toast_status_updated'.tr());
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        AppPlatformBadge(platform: lead.socialPost?.platform),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Inquired Property Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: context.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.apartment_rounded, size: 16, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          propertyDisplay,
                          style: AppTextStyles.caption.copyWith(
                            color: context.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Row: Assigned Broker Pill & Chevron
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasBroker ? AppColors.secondaryLight : context.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasBroker
                              ? AppColors.secondary.withValues(alpha: 0.2)
                              : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 13,
                            color: hasBroker ? AppColors.secondary : context.textColorMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            brokerName,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: hasBroker ? AppColors.secondary : context.textColorMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, size: 20, color: context.textColorMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
