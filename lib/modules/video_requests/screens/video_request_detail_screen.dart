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
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: Text('Video request detail not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Request Detail'),
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
                        title: 'Property Details',
                        icon: Icons.apartment_rounded,
                        children: [
                          _buildDetailRow(context, 'Title', req.property?.propertyTitle ?? '-'),
                          _buildDetailRow(
                            context,
                            'Listing Type',
                            req.property?.listingType.name.toUpperCase() ?? '-',
                          ),
                          _buildDetailRow(context, 'Price', req.property?.price.formatCurrency ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context,
                        title: 'Broker Details',
                        icon: Icons.business_rounded,
                        children: [
                          _buildDetailRow(context, 'Business Name', req.broker?.businessName ?? '-'),
                          _buildDetailRow(context, 'Plan Tier', req.broker?.plan ?? '-'),
                          _buildDetailRow(context, 'Active', req.broker?.isActive == true ? 'YES' : 'NO'),
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
                        title: 'Metadata & Notes',
                        icon: Icons.notes_rounded,
                        children: [
                          _buildDetailRow(
                            context,
                            'Created At',
                            req.createdAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt!)
                                : '-',
                          ),
                          _buildDetailRow(
                            context,
                            'Completed At',
                            req.completedAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(req.completedAt!)
                                : '-',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Broker Notes:',
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req.notes ?? 'No notes provided.',
                            style: AppTextStyles.body2.copyWith(color: context.textColorMuted),
                          ),
                        ],
                      ),
                      if (req.adminApprovalStatus == VideoRequestApprovalStatus.rejected) ...[
                        const SizedBox(height: 20),
                        _buildInfoCard(
                          context,
                          title: 'Rejection Details',
                          icon: Icons.cancel_outlined,
                          isDanger: true,
                          children: [
                            Text(
                              req.adminCancelReason ?? 'No reason provided.',
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
            'Action Needed: ',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject Request'),
            onPressed: () {
              VideoRequestActionDialog.show(
                context,
                isApproval: false,
                onSubmit: (reason) async {
                  final prov = context.read<VideoRequestsProvider>();
                  final success = await prov.rejectRequest(req.id!, reason: reason);
                  if (success) {
                    AppToast.showSuccess('Rejected', 'Video request rejected successfully.');
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
            label: const Text('Approve Request'),
            onPressed: () {
              VideoRequestActionDialog.show(
                context,
                isApproval: true,
                onSubmit: (notes) async {
                  final prov = context.read<VideoRequestsProvider>();
                  final success = await prov.approveRequest(req.id!, notes: notes);
                  if (success) {
                    AppToast.showSuccess('Approved', 'Video request approved successfully.');
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
