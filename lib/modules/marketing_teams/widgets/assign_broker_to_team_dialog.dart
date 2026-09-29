// File: lib/modules/marketing_teams/widgets/assign_broker_to_team_dialog.dart
// Purpose: Modal to assign an unassigned broker directly to the current marketing team, with optional primary rep and notes.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:realty_bazaar_admin/widgets/inputs/app_dropdown.dart';

import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../services/marketing_team_service.dart';

class AssignBrokerToTeamDialog extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<TeamMemberModel> teamMembers;

  const AssignBrokerToTeamDialog({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamMembers,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    required String teamName,
    required List<TeamMemberModel> teamMembers,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          AssignBrokerToTeamDialog(teamId: teamId, teamName: teamName, teamMembers: teamMembers),
    );
  }

  @override
  State<AssignBrokerToTeamDialog> createState() => _AssignBrokerToTeamDialogState();
}

class _AssignBrokerToTeamDialogState extends State<AssignBrokerToTeamDialog> {
  final MarketingTeamService _service = MarketingTeamService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoadingBrokers = true;
  String? _error;
  List<BrokerModel> _unassignedBrokers = [];
  String? _selectedBrokerId;
  String? _selectedPrimaryUserId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUnassignedBrokers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUnassignedBrokers() async {
    setState(() {
      _isLoadingBrokers = true;
      _error = null;
    });

    try {
      final brokers = await _service.fetchUnassignedBrokers(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _unassignedBrokers = brokers;
          _isLoadingBrokers = false;
          if (_selectedBrokerId != null && !_unassignedBrokers.any((b) => b.id == _selectedBrokerId)) {
            _selectedBrokerId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBrokers = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleAssign() async {
    if (_selectedBrokerId == null) {
      AppToast.showError('Select Broker', 'Please select a broker to assign to this team.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.assignBrokerToTeam(
        brokerId: _selectedBrokerId!,
        teamId: widget.teamId,
        primaryUserId: _selectedPrimaryUserId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        AppToast.showSuccess(
          'Broker Assigned',
          'Broker and associated video requests assigned to ${widget.teamName}.',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppToast.showError('Error', e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      title: 'Assign Broker to Team',
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Assigning to team: ${widget.teamName}',
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Search & Broker Selection
              Text(
                'Select Unassigned Broker',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Search field
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadUnassignedBrokers(),
                decoration: InputDecoration(
                  hintText: 'Search unassigned brokers by name or phone...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadUnassignedBrokers,
                    tooltip: 'Refresh list',
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),

              if (_isLoadingBrokers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!, style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                )
              else if (_unassignedBrokers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'No unassigned brokers found matching your criteria.',
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                )
              else
                AppDropdown<String?>(
                  value: _selectedBrokerId,
                  hintText: 'Select a broker to assign',
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Choose a broker...')),
                    ..._unassignedBrokers.map((broker) {
                      final name = broker.businessName ?? broker.userId?.name ?? 'Unknown Broker';
                      final phone = broker.userId?.phone != null ? ' (${broker.userId!.phone})' : '';
                      return DropdownMenuItem<String?>(
                        value: broker.id,
                        child: Text('$name$phone', overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedBrokerId = val);
                  },
                ),

              const SizedBox(height: 18),

              // Primary Rep Dropdown
              Text(
                'Primary Representative (Optional)',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              AppDropdown<String?>(
                value: _selectedPrimaryUserId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None (Team Shared Only)')),
                  ...widget.teamMembers.map((member) {
                    final userName = member.user?.name ?? member.user?.email ?? 'Staff Member';
                    final leadSuffix = member.isLead ? ' (Team Lead)' : '';
                    return DropdownMenuItem<String?>(
                      value: member.userId,
                      child: Text('$userName$leadSuffix'),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedPrimaryUserId = val);
                },
              ),

              const SizedBox(height: 18),

              // Assignment Notes
              Text(
                'Assignment Notes / Reason',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Assigned for regional portfolio management...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Video Requests Sync Notice Callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.video_camera_back_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All existing past and future video requests for this broker will be linked to ${widget.teamName}. Members of this team will be able to review and manage them.',
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'cancel'.tr(),
          variant: AppButtonVariant.outline,
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Assign Broker',
          isLoading: _isSubmitting,
          onPressed: _selectedBrokerId == null ? null : _handleAssign,
        ),
      ],
    );
  }
}
