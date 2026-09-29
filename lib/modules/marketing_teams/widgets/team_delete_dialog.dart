// File: lib/modules/marketing_teams/widgets/team_delete_dialog.dart
// Purpose: Safe team deletion modal with broker reassignment or unassign options.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/customized_dropdown.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../services/marketing_team_service.dart';

class TeamDeleteDialog extends StatefulWidget {
  final MarketingTeamModel team;
  final List<MarketingTeamModel> otherActiveTeams;

  const TeamDeleteDialog({super.key, required this.team, required this.otherActiveTeams});

  static Future<Map<String, dynamic>?> show(BuildContext context, {required MarketingTeamModel team}) async {
    // Fetch other active teams for reassignment dropdown
    final allActive = await MarketingTeamService().fetchActiveTeams();
    final otherTeams = allActive.where((t) => t.id != team.id).toList();

    if (!context.mounted) return null;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TeamDeleteDialog(team: team, otherActiveTeams: otherTeams),
    );
  }

  @override
  State<TeamDeleteDialog> createState() => _TeamDeleteDialogState();
}

class _TeamDeleteDialogState extends State<TeamDeleteDialog> {
  // 'unassign' or 'reassign'
  String _action = 'unassign';
  String? _selectedTargetTeamId;

  @override
  void initState() {
    super.initState();
    if (widget.otherActiveTeams.isNotEmpty) {
      _selectedTargetTeamId = widget.otherActiveTeams.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBrokers = widget.team.brokersCount > 0;

    return AppDialog(
      title: 'Delete Team: ${widget.team.name}',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Are you sure you want to delete this marketing team? This action cannot be undone.',
                      style: AppTextStyles.body2.copyWith(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.team.membersCount > 0) ...[
              Text(
                '• ${widget.team.membersCount} field members will be unlinked from this team.',
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
            if (hasBrokers) ...[
              Text(
                'This team currently has ${widget.team.brokersCount} assigned broker(s). Choose how to handle them:',
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Move to Unassigned Backlog'),
                subtitle: const Text('Brokers will become unassigned and can be reassigned later.'),
                value: 'unassign',
                groupValue: _action,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _action = val!),
              ),
              if (widget.otherActiveTeams.isNotEmpty) ...[
                RadioListTile<String>(
                  title: const Text('Reassign to Another Team'),
                  subtitle: const Text('Transfer all assigned brokers directly to an active team.'),
                  value: 'reassign',
                  groupValue: _action,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _action = val!),
                ),
                if (_action == 'reassign') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: CustomizedDropdown<String>(
                      label: 'Target Marketing Team',
                      value: _selectedTargetTeamId,
                      items: widget.otherActiveTeams.map((t) => t.id).toList(),
                      showAllOption: false,
                      displayValue: (id) {
                        final found = widget.otherActiveTeams.firstWhere(
                          (t) => t.id == id,
                          orElse: () => widget.otherActiveTeams.first,
                        );
                        return found.name;
                      },
                      onChanged: (val) => setState(() => _selectedTargetTeamId = val),
                    ),
                  ),
                ],
              ],
            ] else ...[
              Text(
                'This team has no assigned brokers and can be safely removed.',
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(
          text: 'Delete Team',
          color: Colors.redAccent,
          onPressed: () {
            final reassignId = (_action == 'reassign' && hasBrokers) ? _selectedTargetTeamId : null;
            Navigator.of(context).pop({'confirmed': true, 'reassignTeamId': reassignId});
          },
        ),
      ],
    );
  }
}
