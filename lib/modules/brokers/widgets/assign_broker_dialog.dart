// File: lib/modules/brokers/widgets/assign_broker_dialog.dart
// Purpose: Dialog for Super Admins to assign a broker to a Marketing Team and designate a Primary Representative.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:realty_bazaar_admin/widgets/inputs/app_dropdown.dart';

import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../services/marketing_team_service.dart';

class AssignBrokerDialog extends StatefulWidget {
  final BrokerModel broker;

  const AssignBrokerDialog({super.key, required this.broker});

  static Future<bool?> show(BuildContext context, BrokerModel broker) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignBrokerDialog(broker: broker),
    );
  }

  @override
  State<AssignBrokerDialog> createState() => _AssignBrokerDialogState();
}

class _AssignBrokerDialogState extends State<AssignBrokerDialog> {
  final MarketingTeamService _teamService = MarketingTeamService();
  final TextEditingController _notesController = TextEditingController();

  List<MarketingTeamModel> _teams = [];
  List<TeamMemberModel> _teamMembers = [];

  String? _selectedTeamId;
  String? _selectedPrimaryUserId;

  bool _isLoadingTeams = true;
  bool _isLoadingMembers = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.broker.marketingTeamId;
    _selectedPrimaryUserId = widget.broker.primaryMarketingUserId;
    _loadTeams();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoadingTeams = true);
    try {
      final teams = await _teamService.fetchActiveTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoadingTeams = false;
        });
        if (_selectedTeamId != null) {
          _loadTeamMembers(_selectedTeamId!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
        AppToast.showError('Error', 'Failed to load marketing teams: $e');
      }
    }
  }

  Future<void> _loadTeamMembers(String teamId) async {
    setState(() => _isLoadingMembers = true);
    try {
      final members = await _teamService.fetchTeamMembers(teamId);
      if (mounted) {
        setState(() {
          _teamMembers = members;
          _isLoadingMembers = false;
          // Validate whether current selected primary user is in this team
          if (_selectedPrimaryUserId != null &&
              !_teamMembers.any((m) => m.userId == _selectedPrimaryUserId)) {
            _selectedPrimaryUserId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await _teamService.assignBrokerToTeam(
        brokerId: widget.broker.id!,
        teamId: _selectedTeamId,
        primaryUserId: _selectedPrimaryUserId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      //TODO: Send notification to marketing team user

      if (mounted) {
        AppToast.showSuccess(
          'common.success'.tr(),
          _selectedTeamId == null
              ? 'Broker and video requests unassigned from marketing team.'
              : 'Broker and video requests successfully assigned.',
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showError('Error', e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      title: 'Assign Marketing Team',
      content: _isLoadingTeams
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.broker.businessName ?? 'Broker'} (${widget.broker.id?.substring(0, widget.broker.id!.length > 8 ? 8 : widget.broker.id!.length) ?? ''})',
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Team Dropdown Section
                Text(
                  'Marketing Team / Territory',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                AppDropdown<String?>(
                  value: _selectedTeamId,
                  hintText: 'Select Marketing Team',
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned (No Team)', style: TextStyle(color: Colors.redAccent)),
                    ),
                    ..._teams.map((team) {
                      final territoryStr = team.territory != null ? ' • ${team.territory}' : '';
                      return DropdownMenuItem<String?>(
                        value: team.id,
                        child: Text('${team.name}$territoryStr'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTeamId = val;
                      _selectedPrimaryUserId = null;
                      _teamMembers = [];
                    });
                    if (val != null) {
                      _loadTeamMembers(val);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Primary Marketing Representative Dropdown
                if (_selectedTeamId != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Primary Representative (Optional)',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_isLoadingMembers)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String?>(
                    value: _selectedPrimaryUserId,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None (Team Shared Only)')),
                      ..._teamMembers.map((member) {
                        return DropdownMenuItem<String?>(
                          value: member.userId,
                          child: Text(member.user?.name ?? member.user?.email ?? 'Staff Member'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedPrimaryUserId = val);
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Assignment Notes (Audit Log)
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
                    hintText: 'e.g. Assigned for Western region marketing rollout...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // Video Request Sync Notice Callout
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
                          _selectedTeamId == null
                              ? 'Unassigning will move all associated video requests to unassigned backlog.'
                              : 'All existing and future video requests for this broker will be linked to the selected team.',
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'cancel'.tr(),
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(width: 12),
                    AppButton(text: 'Save Assignment', isLoading: _isSaving, onPressed: _handleSave),
                  ],
                ),
              ],
            ),
    );
  }
}
