import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/brokers/brokers_provider.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../providers/video_requests/video_requests_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/video_request_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/video_request_filter_model.dart';
import 'video_requests_screen.dart';

class VideoRequestsDesktop extends StatelessWidget {
  final VideoRequestsScreenState state;

  const VideoRequestsDesktop({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final videoRequestsProv = state.videoRequestsProv;
    final list = videoRequestsProv.requests;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar & Filter Controls
          AppSearchBar(
            hintText: 'video_requests_search_notes_desktop_hint'.tr(),
            onSearch: (query) => state.filterProvider.updateSearch(query),
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            activeFilterCount: state.filterProvider.activeFiltersCount,
            addLabel: 'Add Video Request',
            onAdd: () => _showAddRequestDialog(context, videoRequestsProv),
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: VideoRequestFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),
          const SizedBox(height: 12),

          // Main Table Area & Optional Filter Sidebar
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AppDataTable(
                          isLoading: videoRequestsProv.isLoading,
                          minWidth: 1000,
                          columns: [
                            AppDataColumn(label: 'video_request_col_property'.tr(), flex: 2.5),
                            AppDataColumn(label: 'video_request_col_broker'.tr(), flex: 2),
                            const AppDataColumn(label: 'Marketing Team', flex: 2),
                            AppDataColumn(label: 'video_request_workflow_status_col'.tr(), flex: 1.5),
                            AppDataColumn(label: 'video_request_approval_status_col'.tr(), flex: 1.5),
                            AppDataColumn(label: 'video_request_date_created_col'.tr(), flex: 1.5),
                            AppDataColumn(label: 'video_request_col_actions'.tr(), flex: 1.5),
                          ],
                          rows: list
                              .map((request) => _buildRow(context, request, videoRequestsProv))
                              .toList(),
                        ),
                      ),
                      PaginationWidget(
                        pagination: videoRequestsProv.pagination,
                        currentPage: videoRequestsProv.currentPage,
                        totalPages: videoRequestsProv.totalPages,
                        totalCount: videoRequestsProv.totalCount,
                        isLoading: videoRequestsProv.isLoading,
                        onPageChanged: (page) => videoRequestsProv.setPage(page),
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

  void _showAddRequestDialog(BuildContext context, VideoRequestsProvider prov) async {
    final brokersProv = context.read<BrokersProvider>();
    final propertiesProv = context.read<AdminPropertyProvider>();

    if (brokersProv.brokers.isEmpty || propertiesProv.properties.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      if (brokersProv.brokers.isEmpty) await brokersProv.fetchBrokers();
      if (propertiesProv.properties.isEmpty) {
        await propertiesProv.fetchProperties();
      }
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (context.mounted) {
      VideoRequestEditDialog.show(
        context,
        brokers: brokersProv.brokers,
        properties: propertiesProv.properties,
        onSave: (model) async {
          final id = await prov.createVideoRequest(
            propertyId: model.property!.id!,
            brokerId: model.broker!.id!,
            notes: model.notes,
          );
          if (id != null) {
            AppToast.showSuccess('Request Created', 'Video request created successfully.');
          }
        },
      );
    }
  }

  DataRowItem _buildRow(
    BuildContext context,
    VideoRequestModel request,
    VideoRequestsProvider videoRequestsProv,
  ) {
    return DataRowItem(
      cells: [
        DataCellText(text: request.property?.propertyTitle ?? '-'),
        DataCellText(text: request.broker?.businessName ?? '-'),
        _buildTeamCell(context, request),
        Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(context, request.status)),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildApprovalBadge(context, request.adminApprovalStatus),
        ),
        DataCellText(
          text: request.createdAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt!)
              : '-',
        ),
        DataCellActions(
          onView: () => context.push('/video-requests/detail/${request.id}', extra: request),
          onEdit: () async {
            final brokersProv = context.read<BrokersProvider>();
            final propertiesProv = context.read<AdminPropertyProvider>();
            if (brokersProv.brokers.isEmpty || propertiesProv.properties.isEmpty) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              if (brokersProv.brokers.isEmpty) await brokersProv.fetchBrokers();
              if (propertiesProv.properties.isEmpty) {
                await propertiesProv.fetchProperties();
              }
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
            if (context.mounted) {
              VideoRequestEditDialog.show(
                context,
                request: request,
                brokers: brokersProv.brokers,
                properties: propertiesProv.properties,
                onSave: (updated) {
                  videoRequestsProv.updateVideoRequest(updated);
                  AppToast.showSuccess('Request Updated', 'Video request details updated.');
                },
              );
            }
          },
          onDelete: () => state.confirmAndDeleteRequest(request),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, VideoRequestStatus status) {
    Color bg = context.primaryContainerColor;
    Color fg = context.primaryColor;
    if (status == VideoRequestStatus.completed) {
      bg = context.successContainerColor;
      fg = context.successColor;
    } else if (status == VideoRequestStatus.cancelled) {
      bg = context.errorContainerColor;
      fg = context.errorColor;
    } else if (status == VideoRequestStatus.inProgress) {
      bg = context.infoContainerColor;
      fg = context.infoColor;
    } else if (status == VideoRequestStatus.assigned) {
      bg = context.warningContainerColor;
      fg = context.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.0)),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildApprovalBadge(BuildContext context, VideoRequestApprovalStatus status) {
    Color bg = context.primaryContainerColor;
    Color fg = context.primaryColor;
    if (status == VideoRequestApprovalStatus.approved) {
      bg = context.successContainerColor;
      fg = context.successColor;
    } else if (status == VideoRequestApprovalStatus.rejected) {
      bg = context.errorContainerColor;
      fg = context.errorColor;
    } else if (status == VideoRequestApprovalStatus.pending) {
      bg = context.warningContainerColor;
      fg = context.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10.0)),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildTeamCell(BuildContext context, VideoRequestModel request) {
    final team = request.effectiveMarketingTeam;
    final rep = request.effectivePrimaryRep;

    if (team == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.textColorMuted.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Unassigned',
            style: AppTextStyles.caption.copyWith(
              color: context.textColorMuted,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 14, color: context.primaryColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                team.name,
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600, color: context.textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (rep != null) ...[
          const SizedBox(height: 2),
          Text(
            rep.name ?? rep.email ?? '',
            style: AppTextStyles.caption.copyWith(color: context.textColorMuted, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
