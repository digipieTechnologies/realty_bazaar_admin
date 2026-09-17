import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_text_styles.dart';
import '../../../app/common_ext.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/video_requests/video_requests_provider.dart';
import '../../../widgets/dialogs/video_request_action_dialog.dart';
import '../../../widgets/toast/app_toast.dart';

class VideoRequestDetailScreen extends StatefulWidget {
  final String requestId;
  final VideoRequestModel? request;

  const VideoRequestDetailScreen({super.key, required this.requestId, this.request});

  @override
  State<VideoRequestDetailScreen> createState() => _VideoRequestDetailScreenState();
}

class _VideoRequestDetailScreenState extends State<VideoRequestDetailScreen> {
  VideoRequestModel? _requestState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestState = widget.request;
    if (_requestState == null) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final prov = context.read<VideoRequestsProvider>();
      final request = prov.requests.firstWhere((r) => r.id == widget.requestId);
      setState(() => _requestState = request);
    } catch (e) {
      debugPrint('Error loading request detail: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final req = _requestState;
    if (req == null) {
      return Scaffold(
        appBar: AppBar(title: Text('video_request_details_title'.tr())),
        body: Center(child: Text('video_request_not_found'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('video_request_detail_header'.tr()),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section Card
            _buildStatusHeader(context, req),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Info Cards
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: 'video_request_property_details'.tr(),
                        icon: Icons.apartment_rounded,
                        children: [
                          _buildDetailRow(context, 'properties_title'.tr(), req.property?.propertyTitle ?? '-'),
                          _buildDetailRow(
                            context,
                            'properties_listing_type'.tr(),
                            req.property?.listingType.name.toUpperCase() ?? '-',
                          ),
                          _buildDetailRow(context, 'price'.tr(), req.property?.price.formatCurrency ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context,
                        title: 'video_request_broker_details'.tr(),
                        icon: Icons.business_rounded,
                        children: [
                          _buildDetailRow(context, 'business_name'.tr(), req.broker?.businessName ?? '-'),
                          _buildDetailRow(context, 'plan'.tr(), req.broker?.plan ?? '-'),
                          _buildDetailRow(context, 'status_active'.tr(), req.broker?.isActive == true ? 'common.yes'.tr() : 'common.no'.tr()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Notes / Admin Comments Side-Card
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: 'video_request_metadata_notes'.tr(),
                        icon: Icons.notes_rounded,
                        children: [
                          _buildDetailRow(
                            context,
                            'created_at'.tr(),
                            req.createdAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt!)
                                : '-',
                          ),
                          _buildDetailRow(
                            context,
                            'completed_at'.tr(),
                            req.completedAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(req.completedAt!)
                                : '-',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'video_request_broker_notes_label'.tr(),
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req.notes ?? 'video_request_no_notes'.tr(),
                            style: AppTextStyles.body2.copyWith(color: context.textColorMuted),
                          ),
                        ],
                      ),
                      if (req.adminApprovalStatus == VideoRequestApprovalStatus.rejected) ...[
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          context,
                          title: 'video_request_rejection_details'.tr(),
                          icon: Icons.cancel_outlined,
                          isDanger: true,
                          children: [
                            Text(
                              req.adminCancelReason ?? 'video_request_no_rejection_reason'.tr(),
                              style: AppTextStyles.body2.copyWith(color: context.errorColor),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Super Admin Action Bar
            if (req.adminApprovalStatus == VideoRequestApprovalStatus.pending) ...[
              const SizedBox(height: 32),
              _buildApprovalActionBar(context, req),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, VideoRequestModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.video_camera_back_rounded, size: 40, color: context.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID: ${req.id}',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${req.status.displayName} | Approval: ${req.adminApprovalStatus.displayName}',
                  style: AppTextStyles.body2.copyWith(color: context.textColorMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isDanger = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? context.errorColor.withOpacity(0.5) : context.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDanger ? context.errorColor : context.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDanger ? context.errorColor : context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(color: context.textColorMuted)),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalActionBar(BuildContext context, VideoRequestModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'video_request_action_needed'.tr(),
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: Text('video_request_reject_btn'.tr()),
            onPressed: () {
              VideoRequestActionDialog.show(
                context,
                isApproval: false,
                onSubmit: (reason) async {
                  final prov = context.read<VideoRequestsProvider>();
                  final success = await prov.rejectRequest(req.id!, reason: reason);
                  if (success) {
                    AppToast.showSuccess('video_request_toast_rejected_title'.tr(), 'video_request_toast_rejected_msg'.tr());
                    setState(() {
                      _requestState = prov.requests.firstWhere((r) => r.id == req.id);
                    });
                  }
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: Text('video_request_approve_btn'.tr()),
            onPressed: () {
              VideoRequestActionDialog.show(
                context,
                isApproval: true,
                onSubmit: (notes) async {
                  final prov = context.read<VideoRequestsProvider>();
                  final success = await prov.approveRequest(req.id!, notes: notes);
                  if (success) {
                    AppToast.showSuccess('video_request_toast_approved_title'.tr(), 'video_request_toast_approved_msg'.tr());
                    setState(() {
                      _requestState = prov.requests.firstWhere((r) => r.id == req.id);
                    });
                  }
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
