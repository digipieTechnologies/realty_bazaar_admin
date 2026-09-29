// File: lib/modules/marketing_teams/widgets/team_edit_dialog.dart
// Purpose: Dialog for creating or editing Marketing Teams with name, territory, description, and status.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/inputs/app_textfield.dart';

class TeamEditDialog extends StatefulWidget {
  final MarketingTeamModel? team;
  final ValueChanged<MarketingTeamModel> onSave;

  const TeamEditDialog({
    super.key,
    this.team,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    MarketingTeamModel? team,
    required ValueChanged<MarketingTeamModel> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TeamEditDialog(team: team, onSave: onSave),
    );
  }

  @override
  State<TeamEditDialog> createState() => _TeamEditDialogState();
}

class _TeamEditDialogState extends State<TeamEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _territoryController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team?.name ?? '');
    _territoryController = TextEditingController(text: widget.team?.territory ?? '');
    _descriptionController = TextEditingController(text: widget.team?.description ?? '');
    _isActive = widget.team?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _territoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final updated = (widget.team ??
            MarketingTeamModel(
              id: '',
              name: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      name: _nameController.text.trim(),
      territory: _territoryController.text.trim().isEmpty ? null : _territoryController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      isActive: _isActive,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.team != null;

    return AppDialog(
      title: isEditing ? 'Edit Marketing Team' : 'Create Marketing Team',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Information',
                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
              ),
              AppTextField(
                label: 'Team Name *',
                hintText: 'e.g. Pune Central Champions',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Team name is required';
                  }
                  return null;
                },
              ),
              AppTextField(
                label: 'Territory / Region',
                hintText: 'e.g. Baner, Hinjewadi & Wakad',
                controller: _territoryController,
              ),
              AppTextField(
                label: 'Description',
                hintText: 'Brief description of the team and focus areas...',
                controller: _descriptionController,
                maxLines: 3,
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: Text(
                    _isActive ? 'Team is active and accepting broker assignments' : 'Team is paused/inactive',
                    style: AppTextStyles.caption,
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(
          text: 'cancel'.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        AppButton.solid(
          text: isEditing ? 'save'.tr() : 'Create Team',
          onPressed: _handleSave,
        ),
      ],
    );
  }
}
