import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/account_deletion_requests/account_deletion_requests_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/toast/app_toast.dart';

class AccountDeletionRequestsScreen extends StatefulWidget {
  const AccountDeletionRequestsScreen({super.key});

  @override
  State<AccountDeletionRequestsScreen> createState() =>
      _AccountDeletionRequestsScreenState();
}

class _AccountDeletionRequestsScreenState
    extends State<AccountDeletionRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountDeletionRequestsProvider>().fetchRequests();
    });
  }

  Future<void> _approve(AccountDeletionRequestModel req) async {
    // In a real app, get admin ID from auth state
    final prov = context.read<AccountDeletionRequestsProvider>();
    final success = await prov.approveRequest(req.id, 'admin');
    if (success && mounted) {
      AppToast.showSuccess('Approved', 'Deletion request approved successfully.');
    }
  }

  Future<void> _reject(AccountDeletionRequestModel req) async {
    final prov = context.read<AccountDeletionRequestsProvider>();
    final success = await prov.rejectRequest(req.id, 'admin');
    if (success && mounted) {
      AppToast.showSuccess('Rejected', 'Deletion request rejected.');
    }
  }

  void _confirmAction(AccountDeletionRequestModel req, bool isApprove) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isApprove ? 'Approve Deletion' : 'Reject Request'),
        content: Text(
          isApprove
              ? 'This will approve deletion for ${req.email ?? req.phone ?? 'this account'}. The account will be scheduled for ${req.deletionType} deletion. Are you sure?'
              : 'Are you sure you want to reject this deletion request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isApprove ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (isApprove) {
                _approve(req);
              } else {
                _reject(req);
              }
            },
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AccountDeletionRequestsProvider>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Account Deletion Requests'),
        elevation: 0,
        backgroundColor: context.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusFilters(prov),
            const SizedBox(height: 12),
            Expanded(
              child: AppDataTable(
                isLoading: prov.isLoading,
                columns: const [
                  AppDataColumn(label: 'Account', flex: 2),
                  AppDataColumn(label: 'Type', flex: 1),
                  AppDataColumn(label: 'Deletion', flex: 1),
                  AppDataColumn(label: 'Reason', flex: 2),
                  AppDataColumn(label: 'Requested At', flex: 2),
                  AppDataColumn(label: 'Status', flex: 1),
                  AppDataColumn(label: 'Actions', flex: 2),
                ],
                rows: prov.requests.map((r) => _buildRow(r)).toList(),
              ),
            ),
            PaginationWidget(
              pagination: prov.pagination,
              currentPage: prov.currentPage,
              totalPages: prov.totalPages,
              totalCount: prov.totalCount,
              isLoading: prov.isLoading,
              onPageChanged: prov.setPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters(AccountDeletionRequestsProvider prov) {
    const statuses = ['All', 'pending', 'approved', 'rejected'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final isSelected = s == 'All'
              ? prov.statusFilter == null
              : prov.statusFilter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_capitalize(s)),
              selected: isSelected,
              onSelected: (_) => prov.setStatusFilter(s),
            ),
          );
        }).toList(),
      ),
    );
  }

  DataRowItem _buildRow(AccountDeletionRequestModel req) {
    return DataRowItem(
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (req.email != null)
              Text(req.email!, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
            if (req.phone != null)
              Text(req.phone!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            if (req.userId != null)
              Text('User', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            if (req.brokerId != null && req.userId == null)
              Text('Broker', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        Text(req.userId != null ? 'User' : 'Broker', style: AppTextStyles.body2),
        _deletionTypeChip(req.deletionType),
        Text(req.reason ?? '-', style: AppTextStyles.body2, maxLines: 2, overflow: TextOverflow.ellipsis),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('dd MMM yyyy').format(req.requestedAt), style: AppTextStyles.body2),
            Text(DateFormat('hh:mm a').format(req.requestedAt), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        _statusChip(req.status),
        req.isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn('Approve', AppColors.success, () => _confirmAction(req, true)),
                  const SizedBox(width: 4),
                  _actionBtn('Reject', AppColors.error, () => _confirmAction(req, false)),
                ],
              )
            : Text(_capitalize(req.status),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _deletionTypeChip(String type) {
    final isHard = type == 'hard';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHard ? AppColors.errorLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _capitalize(type),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isHard ? AppColors.error : AppColors.warning,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (bg, fg) = switch (status) {
      'approved' => (AppColors.successLight, AppColors.success),
      'rejected' => (AppColors.errorLight, AppColors.error),
      _ => (AppColors.warningLight, AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(_capitalize(status),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
