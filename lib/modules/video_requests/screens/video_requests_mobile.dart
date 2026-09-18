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
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/video_request_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/video_request_filter_model.dart';
import 'video_requests_screen.dart';

class VideoRequestsMobile extends StatelessWidget {
  final VideoRequestsScreenState state;

  const VideoRequestsMobile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final videoRequestsProv = state.videoRequestsProv;
    final list = videoRequestsProv.requests;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              hintText: 'video_requests_search_hint'.tr(),
              onSearch: (query) => state.filterProvider.updateSearch(query),
              isMobile: true,
              onFilter: state.showFilterBottomSheet,
              activeFilterCount: state.filterProvider.activeFiltersCount,
              onAdd: () => _showAddRequestDialog(context, videoRequestsProv),
              addLabel: 'video_requests_create_title'.tr(),
            ),
            const SizedBox(height: 8),
            EnterpriseQuickFilters(
              provider: state.filterProvider,
              fields: VideoRequestFilterModel.filterDefinition.fields
                  .where((f) => f.type == FilterType.quickFilter)
                  .toList(),
              isMobile: true,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => videoRequestsProv.refresh(),
                child: videoRequestsProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? Center(child: Text('no_data'.tr(), style: AppTextStyles.body2))
                        : ListView.separated(
                            itemCount: list.length,
                            padding: const EdgeInsets.only(bottom: 80),
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final request = list[index];
                              return _buildCard(context, request, videoRequestsProv);
                            },
                          ),
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
      if (propertiesProv.properties.isEmpty) await propertiesProv.fetchProperties();
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

  Widget _buildCard(
    BuildContext context,
    VideoRequestModel request,
    VideoRequestsProvider videoRequestsProv,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: () => context.push('/video-requests/detail/${request.id}', extra: request),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Property Title & Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.property?.propertyTitle ?? 'Property Title',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Broker: ${request.broker?.businessName ?? "-"}',
                            style: AppTextStyles.body2.copyWith(color: context.textColorMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: context.textColorMuted),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Badges Row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatusBadge(context, request.status),
                    _buildApprovalBadge(context, request.adminApprovalStatus),
                  ],
                ),

                if (request.notes != null && request.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.notes!,
                      style: AppTextStyles.caption.copyWith(color: context.textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 6),

                // Action Footer
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: context.textColorMuted),
                    const SizedBox(width: 6),
                    Text(
                      request.createdAt != null ? DateFormat('dd MMM yyyy').format(request.createdAt!) : '-',
                      style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: context.primaryColor, size: 20),
                      tooltip: 'edit'.tr(),
                      onPressed: () async {
                        final brokersProv = context.read<BrokersProvider>();
                        final propertiesProv = context.read<AdminPropertyProvider>();
                        if (brokersProv.brokers.isEmpty || propertiesProv.properties.isEmpty) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          if (brokersProv.brokers.isEmpty) await brokersProv.fetchBrokers();
                          if (propertiesProv.properties.isEmpty) await propertiesProv.fetchProperties();
                          if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                        }
                        if (context.mounted) {
                          VideoRequestEditDialog.show(
                            context,
                            request: request,
                            brokers: brokersProv.brokers,
                            properties: propertiesProv.properties,
                            onSave: (updated) {
                              videoRequestsProv.updateVideoRequest(updated);
                              AppToast.showSuccess('Request Updated', 'Video request updated.');
                            },
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: context.errorColor, size: 20),
                      tooltip: 'delete'.tr(),
                      onPressed: () => state.confirmAndDeleteRequest(request),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
        'Status: ${status.displayName.toUpperCase()}',
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
        'Approval: ${status.displayName.toUpperCase()}',
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
