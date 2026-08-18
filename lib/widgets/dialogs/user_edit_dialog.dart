// File: lib/widgets/dialogs/user_edit_dialog.dart
// Purpose: Modal dialog for editing user profile (Name, Phone, Role, Gender, DOB, Notes, Active Status).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/enums/gender_enum.dart';
import '../../models/models.dart';
import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_date_field.dart';
import '../inputs/app_phone_text_field.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel user;
  final ValueChanged<UserModel> onSave;

  const UserEditDialog({super.key, required this.user, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required UserModel user,
    required ValueChanged<UserModel> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => UserEditDialog(user: user, onSave: onSave),
    );
  }

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late UserRole _role;
  late Gender _gender;
  DateTime? _dob;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _notesController = TextEditingController(text: widget.user.notes ?? '');
    _role = widget.user.role;
    _gender = widget.user.gender;
    _dob = widget.user.dob;
    _isActive = widget.user.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'users_edit_profile'.tr(),
      content: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'full_name'.tr(), controller: _nameController),

            AppTextField(
              label: 'email'.tr(),
              controller: _emailController,
              enabled: false,
              fillColor: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            ),

            AppPhoneTextField(label: 'phone'.tr(), controller: _phoneController),

            CustomizedDropdown<UserRole>(
              label: 'role'.tr(),
              value: _role,
              enableSearch: false,
              items: UserRole.values.where((r) => r != UserRole.unknown).toList(),
              showAllOption: false,
              displayValue: (r) => r.displayName,
              onChanged: (val) {
                if (val != null) setState(() => _role = val);
              },
            ),

            CustomizedDropdown<Gender>(
              label: 'users_gender'.tr(),
              value: _gender,
              enableSearch: false,
              items: Gender.values,
              showAllOption: false,
              displayValue: (g) => g.displayName(context),
              onChanged: (val) {
                if (val != null) setState(() => _gender = val);
              },
            ),

            AppDateField(
              label: 'users_dob'.tr(),
              hintText: 'select_dob'.tr(),
              value: _dob,
              lastDate: DateTime.now(),
              initialDate: _dob ?? DateTime(2000, 1, 1),
              onChanged: (val) => setState(() => _dob = val),
            ),

            AppTextField(label: 'users_notes'.tr(), controller: _notesController, maxLines: 3),

            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('active_status'.tr()),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(),
          ],
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(
          text: 'save'.tr(),
          onPressed: () {
            final updated = widget.user.copyWith(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              phoneCountryCode: widget.user.phoneCountryCode ?? '91',
              phoneCountryIso: widget.user.phoneCountryIso ?? 'IN',
              role: _role,
              gender: _gender,
              dob: _dob,
              notes: _notesController.text.trim(),
              isActive: _isActive,
            );
            widget.onSave(updated);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
