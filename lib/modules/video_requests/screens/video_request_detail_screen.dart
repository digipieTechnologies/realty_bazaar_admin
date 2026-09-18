import 'package:collection/collection.dart';
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

  const VideoRequestDetailScreen({super.key, required this.requestId});

  @override
  State<VideoRequestDetailScreen> createState() => _VideoRequestDetailScreenState();
}

class _VideoRequestDetailScreenState extends State<VideoRequestDetailScreen> {
  VideoRequestModel? _requestState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setStateIfMounted(() => _isLoading = true);
    try {
      final prov = context.read<VideoRequestsProvider>();
      final request = await prov.fetchRequestById(widget.requestId);
      if (request != null) {
        setStateIfMounted(() => _requestState = request);
      }
    } catch (e) {
      debugPrint('Error loading request detail: $e');
    } finally {
      setStateIfMounted(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoRequestsProv = context.watch<VideoRequestsProvider>();

    if (_isLoading && _requestState == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('video_request_detail_header'.tr()),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final req = _requestState ?? videoRequestsProv.requests.firstWhereOrNull((r) => r.id == widget.requestId);
    if (req == null) {
      return Scaffold(
        appBar: AppBar(title: Text('video_request_details_title'.tr())),
        body: Center(child: Text('video_request_not_found'.tr())),
      );
    }

    final activeReq = req;
    final isDesktop = context.isDesktop;
    final paddingAmount = isDesktop ? 24.0 : 16.0;

    final propertyCard = _buildInfoCard(
      context,
      title: 'video_request_property_details'.tr(),
      icon: Icons.apartment_rounded,
      children: [
        _buildDetailRow(context, 'properties_title'.tr(), activeReq.property?.propertyTitle ?? '-'),
        _buildDetailRow(
          context,
          'properties_listing_type'.tr(),
          activeReq.property?.listingType.name.toUpperCase() ?? '-',
        ),
        _buildDetailRow(context, 'price'.tr(), activeReq.property?.price.formatCurrency ?? '-'),
      ],
    );

    final brokerCard = _buildInfoCard(
      context,
      title: 'video_request_broker_details'.tr(),
      icon: Icons.business_rounded,
      children: [
        _buildDetailRow(context, 'business_name'.tr(), activeReq.broker?.businessName ?? '-'),
        _buildDetailRow(context, 'plan'.tr(), activeReq.broker?.plan ?? '-'),
        _buildDetailRow(
          context,
          'status_active'.tr(),
          activeReq.broker?.isActive == true ? 'common.yes'.tr() : 'common.no'.tr(),
        ),
      ],
    );

    final notesCard = _buildInfoCard(
      context,
      title: 'video_request_metadata_notes'.tr(),
      icon: Icons.notes_rounded,
      children: [
        _buildDetailRow(
          context,
          'created_at'.tr(),
          activeReq.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(activeReq.createdAt!) : '-',
        ),
        _buildDetailRow(
          context,
          'completed_at'.tr(),
          activeReq.completedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(activeReq.completedAt!) : '-',
        ),
        const SizedBox(height: 12),
        Text(
          'video_request_broker_notes_label'.tr(),
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        const SizedBox(height: 4),
        Text(
          activeReq.notes ?? 'video_request_no_notes'.tr(),
          style: AppTextStyles.body2.copyWith(color: context.textColorMuted),
        ),
      ],
    );

    Widget? rejectionCard;
    if (activeReq.adminApprovalStatus == VideoRequestApprovalStatus.rejected) {
      rejectionCard = _buildInfoCard(
        context,
        title: 'video_request_rejection_details'.tr(),
        icon: Icons.cancel_outlined,
        isDanger: true,
        children: [
          Text(
            activeReq.adminCancelReason ?? 'video_request_no_rejection_reason'.tr(),
            style: AppTextStyles.body2.copyWith(color: context.errorColor),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('video_request_detail_header'.tr()),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(paddingAmount),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section Card
            _buildStatusHeader(context, activeReq, isDesktop: isDesktop),
            const SizedBox(height: 20),

            // Content Layout: Row on Desktop, Column on Mobile
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: Column(children: [propertyCard, const SizedBox(height: 20), brokerCard])),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        notesCard,
                        if (rejectionCard != null) ...[const SizedBox(height: 20), rejectionCard],
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  propertyCard,
                  const SizedBox(height: 16),
                  brokerCard,
                  const SizedBox(height: 16),
                  notesCard,
                  if (rejectionCard != null) ...[const SizedBox(height: 16), rejectionCard],
                ],
              ),

            // Super Admin Action Bar
            if (activeReq.adminApprovalStatus == VideoRequestApprovalStatus.pending) ...[
              const SizedBox(height: 24),
              _buildApprovalActionBar(context, activeReq, isDesktop: isDesktop),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, VideoRequestModel req, {required bool isDesktop}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request ID: ${req.id}',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: context.textColor),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildBadgeChip(
              context,
              label: 'Workflow: ${req.status.displayName.toUpperCase()}',
              color: req.status == VideoRequestStatus.completed
                  ? context.successColor
                  : (req.status == VideoRequestStatus.cancelled ? context.errorColor : context.primaryColor),
              bgColor: req.status == VideoRequestStatus.completed
                  ? context.successContainerColor
                  : (req.status == VideoRequestStatus.cancelled
                        ? context.errorContainerColor
                        : context.primaryContainerColor),
            ),
            _buildBadgeChip(
              context,
              label: 'Approval: ${req.adminApprovalStatus.displayName.toUpperCase()}',
              color: req.adminApprovalStatus == VideoRequestApprovalStatus.approved
                  ? context.successColor
                  : (req.adminApprovalStatus == VideoRequestApprovalStatus.rejected
                        ? context.errorColor
                        : context.warningColor),
              bgColor: req.adminApprovalStatus == VideoRequestApprovalStatus.approved
                  ? context.successContainerColor
                  : (req.adminApprovalStatus == VideoRequestApprovalStatus.rejected
                        ? context.errorContainerColor
                        : context.warningContainerColor),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.primaryContainerColor, shape: BoxShape.circle),
            child: Icon(Icons.video_camera_back_rounded, size: isDesktop ? 32 : 24, color: context.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(BuildContext context, {required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDanger ? context.errorColor.withOpacity(0.5) : context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDanger ? context.errorColor : context.primaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDanger ? context.errorColor : context.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(color: context.textColorMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600, color: context.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalActionBar(BuildContext context, VideoRequestModel req, {required bool isDesktop}) {
    final rejectBtn = ElevatedButton.icon(
      icon: const Icon(Icons.cancel_outlined, size: 18),
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
              final updated = prov.requests.firstWhereOrNull((r) => r.id == req.id);
              if (updated != null) {
                setStateIfMounted(() {
                  _requestState = updated;
                });
              }
            }
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: context.errorColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    final approveBtn = ElevatedButton.icon(
      icon: const Icon(Icons.check_circle_outline, size: 18),
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
              final updated = prov.requests.firstWhereOrNull((r) => r.id == req.id);
              if (updated != null) {
                setStateIfMounted(() {
                  _requestState = updated;
                });
              }
            }
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: isDesktop
          ? Row(
              children: [
                Text(
                  'video_request_action_needed'.tr(),
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: context.textColor),
                ),
                const Spacer(),
                rejectBtn,
                const SizedBox(width: 16),
                approveBtn,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'video_request_action_needed'.tr(),
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: context.textColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: rejectBtn),
                    const SizedBox(width: 12),
                    Expanded(child: approveBtn),
                  ],
                ),
              ],
            ),
    );
  }
}
