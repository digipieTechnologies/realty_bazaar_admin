// File: lib/modules/support/widgets/admin_create_ticket_dialog.dart
// Purpose: Modal dialog allowing admins to open a support ticket on behalf of a selected broker.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/support/admin_support_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/inputs/app_dropdown.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/inputs/broker_typeahead_field.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminCreateTicketDialog extends StatefulWidget {
  const AdminCreateTicketDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AdminCreateTicketDialog(),
    );
  }

  @override
  State<AdminCreateTicketDialog> createState() => _AdminCreateTicketDialogState();
}

class _AdminCreateTicketDialogState extends State<AdminCreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBrokerId;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  SupportCategory _selectedCategory = SupportCategory.general;
  SupportTicketPriority _selectedPriority = SupportTicketPriority.normal;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedBrokerId == null || _selectedBrokerId!.isEmpty) {
      AppToast.showError('please_select_broker'.tr());
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<AdminSupportProvider>();
    final success = await provider.createTicketOnBehalfOfBroker(
      brokerId: _selectedBrokerId!,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      category: _selectedCategory.dbValue,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority.dbValue,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        AppToast.showSuccess('ticket_created_successfully'.tr());
        Navigator.of(context).pop();
      } else {
        AppToast.showError('error_creating_ticket'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final dialogWidth = isDesktop ? 640.0 : MediaQuery.of(context).size.width * 0.95;
    final dialogMaxHeight = MediaQuery.of(context).size.height * 0.85;

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
            // ── Header ────────────────────────────────────────────────────
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
                    child: const Icon(
                      Icons.add_comment_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'create_ticket_title'.tr(),
                          style: AppTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'create_ticket_subtitle'.tr(),
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

            // ── Form Body ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Broker Selection
                      BrokerTypeAheadField(
                        selectedBrokerId: _selectedBrokerId,
                        onBrokerChanged: (id) {
                          setState(() => _selectedBrokerId = id);
                        },
                        label: 'select_broker'.tr(),
                        hintText: 'search_broker_hint'.tr(),
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Requester Full Name
                      AppTextField(
                        controller: _fullNameController,
                        label: 'requester_name'.tr(),
                        hintText: 'enter_requester_name'.tr(),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'field_required'.tr() : null,
                      ),
                      const SizedBox(height: 16),

                      // Email & Phone
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _emailController,
                              label: 'email'.tr(),
                              hintText: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@')) ? 'invalid_email'.tr() : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _phoneController,
                              label: 'phone'.tr(),
                              hintText: '+91 9876543210',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category & Priority
                      Row(
                        children: [
                          Expanded(
                            child: AppDropdown<SupportCategory>(
                              label: 'category'.tr(),
                              value: _selectedCategory,
                              items: SupportCategory.values.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c.labelKey.tr()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
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

                      // Subject
                      AppTextField(
                        controller: _subjectController,
                        label: 'subject'.tr(),
                        hintText: 'ticket_subject_hint'.tr(),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'field_required'.tr() : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        controller: _descriptionController,
                        label: 'description'.tr(),
                        hintText: 'ticket_description_hint'.tr(),
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'field_required'.tr() : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    text: 'cancel'.tr(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton.solid(
                    text: 'create_ticket'.tr(),
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
