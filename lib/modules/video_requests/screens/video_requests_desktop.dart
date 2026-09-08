import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hintText: 'video_requests_search_notes_desktop_hint'.tr(),
            onSearch: (query) => state.filterProvider.updateSearch(query),
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            activeFilterCount: state.filterProvider.activeFiltersCount,
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: VideoRequestFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),
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
                          columns: [
                            AppDataColumn(label: 'video_request_col_property'.tr(), flex: 2),
                            AppDataColumn(label: 'video_request_col_broker'.tr(), flex: 2),
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
    // Fetch brokers and properties to populate select dropdowns
    final brokersProv = context.read<BrokersProvider>();
    final propertiesProv = context.read<AdminPropertyProvider>();

    if (brokersProv.brokers.isEmpty) {
      await brokersProv.fetchBrokers();
    }
    if (propertiesProv.properties.isEmpty) {
      await propertiesProv.fetchProperties();
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
            AppToast.showSuccess('Request Created', 'Video request was created successfully.');
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
        Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(request.status)),
        Align(alignment: Alignment.centerLeft, child: _buildApprovalBadge(request.adminApprovalStatus)),
        DataCellText(
          text: request.createdAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt!)
              : '-',
        ),
        DataCellActions(
          onView: () => context.push('/video-requests/detail/${request.id}', extra: request),
          onEdit: () {
            final brokersProv = context.read<BrokersProvider>();
            final propertiesProv = context.read<AdminPropertyProvider>();
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
          },
          onDelete: () => state.confirmAndDeleteRequest(request),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(VideoRequestStatus status) {
    Color bg = AppColors.primaryLight;
    Color fg = AppColors.primary;
    if (status == VideoRequestStatus.completed) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == VideoRequestStatus.cancelled) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else if (status == VideoRequestStatus.inProgress) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    } else if (status == VideoRequestStatus.assigned) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildApprovalBadge(VideoRequestApprovalStatus status) {
    Color bg = AppColors.primaryLight;
    Color fg = AppColors.primary;
    if (status == VideoRequestApprovalStatus.approved) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == VideoRequestApprovalStatus.rejected) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else if (status == VideoRequestApprovalStatus.pending) {
      bg = Colors.yellow.shade100;
      fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
