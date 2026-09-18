// File: lib/modules/support/widgets/admin_ticket_detail_dialog.dart
// Purpose: Super Admin Ticket Detail & Management Modal allowing status transitions, priority updates, internal notes, staff assignment, reopen approvals, and direct broker chat launching.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/support/admin_support_provider.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/cached_image.dart';
import '../../../widgets/inputs/app_dropdown.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/toast/app_toast.dart';
import '../../chat/dialogs/admin_chat_dialog.dart';

class AdminTicketDetailDialog extends StatefulWidget {
  final SupportTicketModel ticket;

  const AdminTicketDetailDialog({super.key, required this.ticket});

  static Future<void> show(BuildContext context, SupportTicketModel ticket) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminTicketDetailDialog(ticket: ticket),
    );
  }

  @override
  State<AdminTicketDetailDialog> createState() => _AdminTicketDetailDialogState();
}

class _AdminTicketDetailDialogState extends State<AdminTicketDetailDialog> {
  late SupportTicketStatus _selectedStatus;
  late SupportTicketPriority _selectedPriority;
  late TextEditingController _adminNotesController;
  String? _selectedAssignedTo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.ticket.statusEnum;
    _selectedPriority = widget.ticket.priorityEnum;
    _selectedAssignedTo = widget.ticket.assignedTo;
    _adminNotesController = TextEditingController(text: widget.ticket.adminNotes ?? '');

    // Fetch users for assignment dropdown if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usersProvider = context.read<UsersProvider>();
      if (usersProvider.users.isEmpty) {
        usersProvider.fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminSupportProvider>();
    final usersProvider = context.read<UsersProvider>();

    bool success = true;

    // Status & Notes
    if (_selectedStatus != widget.ticket.statusEnum ||
        _adminNotesController.text.trim() != (widget.ticket.adminNotes ?? '')) {
      final res = await provider.updateTicketStatus(
        widget.ticket.id,
        _selectedStatus.dbValue,
        adminNotes: _adminNotesController.text.trim(),
      );
      if (!res) success = false;
    }

    // Priority
    if (_selectedPriority != widget.ticket.priorityEnum) {
      final res = await provider.updateTicketPriority(widget.ticket.id, _selectedPriority.dbValue);
      if (!res) success = false;
    }

    // Assignment
    if (_selectedAssignedTo != widget.ticket.assignedTo) {
      final assignedUser = usersProvider.users.where((u) => u.id == _selectedAssignedTo).firstOrNull;
      final res = await provider.assignTicket(
        widget.ticket.id,
        _selectedAssignedTo,
        adminName: assignedUser?.name,
      );
      if (!res) success = false;
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        AppToast.showSuccess('ticket_updated_successfully'.tr());
        Navigator.of(context).pop();
      } else {
        AppToast.showError('error_updating_ticket'.tr());
      }
    }
  }

  Future<void> _handleReopenResponse(bool approve) async {
    setState(() => _isSaving = true);
    final provider = context.read<AdminSupportProvider>();
    final success = await provider.resolveReopenRequest(
      widget.ticket.id,
      approve: approve,
      adminNote: approve ? 'Reopen approved by admin.' : 'Reopen denied by admin.',
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        AppToast.showSuccess(approve ? 'reopen_approved'.tr() : 'reopen_denied'.tr());
        Navigator.of(context).pop();
      } else {
        AppToast.showError('error_updating_ticket'.tr());
      }
    }
  }

  void _openChatDialog() {
    Navigator.of(context).pop();
    AdminChatDialog.show(context, supportTicket: widget.ticket);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final dialogWidth = isDesktop ? 780.0 : MediaQuery.of(context).size.width * 0.95;
    final dialogMaxHeight = MediaQuery.of(context).size.height * 0.88;
    final users = context.watch<UsersProvider>().users;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Modal Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.ticket.ticketNumber,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildBadge(
                              label: widget.ticket.categoryEnum.labelKey.tr(),
                              textColor: AppColors.primary,
                              bgColor: AppColors.primary50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${'created_at'.tr()}: ${_formatDate(widget.ticket.createdAt)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── Scrollable Body Content ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Reopen Request Alert Banner ───────────────────────
                    if (widget.ticket.reopenRequested) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'reopen_requested_title'.tr(),
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.ticket.reopenReason != null &&
                                widget.ticket.reopenReason!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${'reason'.tr()}: "${widget.ticket.reopenReason}"',
                                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                AppButton.solid(
                                  text: 'approve_reopen'.tr(),
                                  color: AppColors.success,
                                  onPressed: _isSaving ? null : () => _handleReopenResponse(true),
                                ),
                                const SizedBox(width: 10),
                                AppButton.outline(
                                  text: 'reject_reopen'.tr(),
                                  onPressed: _isSaving ? null : () => _handleReopenResponse(false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Ticket Core Information ───────────────────────────
                    _buildSectionTitle('ticket_info'.tr()),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  label: 'broker'.tr(),
                                  value: widget.ticket.brokerBusinessName ?? 'N/A',
                                  subtitle: widget.ticket.brokerCode != null
                                      ? 'Code: ${widget.ticket.brokerCode}'
                                      : null,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  label: 'requester_name'.tr(),
                                  value: widget.ticket.fullName,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(label: 'email'.tr(), value: widget.ticket.email),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  label: 'phone'.tr(),
                                  value: widget.ticket.phone ?? '--',
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.border),
                          _buildInfoItem(label: 'subject'.tr(), value: widget.ticket.subject),
                          const SizedBox(height: 12),
                          _buildInfoItem(label: 'description'.tr(), value: widget.ticket.description),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Attachments (if any) ──────────────────────────────
                    if (widget.ticket.attachments.isNotEmpty) ...[
                      _buildSectionTitle('attachments'.tr()),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.ticket.attachments.map((att) {
                          final isImage =
                              att.type?.toLowerCase().contains('image') == true ||
                              (att.url?.toLowerCase().endsWith('.jpg') == true ||
                                  att.url?.toLowerCase().endsWith('.jpeg') == true ||
                                  att.url?.toLowerCase().endsWith('.png') == true);

                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isImage && att.url != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedImage(
                                      imageUrl: att.url!,
                                      height: 70,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Container(
                                    height: 70,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  att.url?.split('/').last ?? 'attachment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Admin Management Section ──────────────────────────
                    _buildSectionTitle('admin_management'.tr()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Status
                        Expanded(
                          child: AppDropdown<SupportTicketStatus>(
                            label: 'status'.tr(),
                            value: _selectedStatus,
                            items: SupportTicketStatus.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s.labelKey.tr()),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatus = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Priority
                        Expanded(
                          child: AppDropdown<SupportTicketPriority>(
                            label: 'priority'.tr(),
                            value: _selectedPriority,
                            items: SupportTicketPriority.values.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p.labelKey.tr()),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPriority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Assign To Staff
                    AppDropdown<String?>(
                      label: 'assigned_to'.tr(),
                      value: _selectedAssignedTo,
                      hint: 'unassigned'.tr(),
                      items: [
                        DropdownMenuItem<String?>(value: null, child: Text('unassigned'.tr())),
                        ...users.map((u) {
                          return DropdownMenuItem<String?>(
                            value: u.id,
                            child: Text(
                              '${u.name ?? u.email ?? 'Staff'} (${(u.role.displayName).toUpperCase()})',
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedAssignedTo = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Internal Admin Notes
                    AppTextField(
                      controller: _adminNotesController,
                      label: 'internal_admin_notes'.tr(),
                      hintText: 'add_internal_notes_hint'.tr(),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer Actions ────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  AppButton.outline(
                    text: 'open_broker_chat'.tr(),
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: _openChatDialog,
                  ),
                  const Spacer(),
                  AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  AppButton.solid(
                    text: 'save_changes'.tr(),
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  Widget _buildInfoItem({required String label, required String value, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
        ],
      ],
    );
  }

  Widget _buildBadge({required String label, required Color textColor, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
