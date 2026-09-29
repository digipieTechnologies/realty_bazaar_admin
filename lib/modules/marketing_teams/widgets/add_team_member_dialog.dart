// File: lib/modules/marketing_teams/widgets/add_team_member_dialog.dart
// Purpose: Modal to add or transfer a marketing staff member to a team with lead designation.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/customized_dropdown.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../services/marketing_team_service.dart';

class AddTeamMemberDialog extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<String> existingMemberUserIds;

  const AddTeamMemberDialog({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.existingMemberUserIds,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    required String teamName,
    required List<String> existingMemberUserIds,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AddTeamMemberDialog(
        teamId: teamId,
        teamName: teamName,
        existingMemberUserIds: existingMemberUserIds,
      ),
    );
  }

  @override
  State<AddTeamMemberDialog> createState() => _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends State<AddTeamMemberDialog> {
  final MarketingTeamService _service = MarketingTeamService();
  bool _isLoading = true;
  String? _error;
  List<AvailableMarketingUser> _availableUsers = [];
  String? _selectedUserId;
  bool _isLead = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _service.fetchAvailableMarketingUsers();
      // Exclude users already in THIS team
      final filtered = users
          .where((u) => u.user.id != null && !widget.existingMemberUserIds.contains(u.user.id))
          .toList();
      setState(() {
        _availableUsers = filtered;
        if (filtered.isNotEmpty) {
          _selectedUserId = filtered.first.user.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  AvailableMarketingUser? get _selectedUser {
    if (_selectedUserId == null) return null;
    return _availableUsers.firstWhere(
      (u) => u.user.id == _selectedUserId,
      orElse: () => _availableUsers.first,
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedUserId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.addOrTransferMember(teamId: widget.teamId, userId: _selectedUserId!, isLead: _isLead);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedUser;
    final isTransfer = selected != null && selected.hasTeam && selected.currentTeamId != widget.teamId;

    return AppDialog(
      title: 'Add Member to ${widget.teamName}',
      content: _isLoading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : _availableUsers.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No available marketing users found.',
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                    ),
                  ],
                  CustomizedDropdown<String>(
                    label: 'Select Marketing User',
                    value: _selectedUserId,
                    items: _availableUsers.map((u) => u.user.id!).toList(),
                    showAllOption: false,
                    displayValue: (id) {
                      final item = _availableUsers.firstWhere((u) => u.user.id == id);
                      final teamSuffix = item.hasTeam ? ' (${item.currentTeamName})' : ' (Unassigned)';
                      return '${item.user.name ?? item.user.email}$teamSuffix';
                    },
                    onChanged: (val) => setState(() => _selectedUserId = val),
                  ),
                  const SizedBox(height: 12),
                  if (isTransfer) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selected.user.name ?? "User"} is currently assigned to "${selected.currentTeamName}". Adding them here will transfer them from their current team.',
                              style: AppTextStyles.caption.copyWith(color: const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: const Text('Designate as Team Lead'),
                      subtitle: Text(
                        _isLead
                            ? 'This user will be set as the lead of ${widget.teamName}'
                            : 'Regular field member',
                        style: AppTextStyles.caption,
                      ),
                      value: _isLead,
                      onChanged: (val) => setState(() => _isLead = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop(false)),
        if (_availableUsers.isNotEmpty) ...[
          const SizedBox(width: 12),
          AppButton.solid(
            text: isTransfer ? 'Transfer & Add' : 'Add Member',
            isLoading: _isSubmitting,
            onPressed: _handleSubmit,
          ),
        ],
      ],
    );
  }
}
