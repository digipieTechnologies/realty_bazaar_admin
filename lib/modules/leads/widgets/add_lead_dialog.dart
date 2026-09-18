// File: lib/modules/leads/widgets/add_lead_dialog.dart
// Purpose: Modal dialog for Super Admins to manually record a new lead or edit an existing lead,
// with broker as main context and broker-scoped properties typeahead.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/lead_status_enum.dart';
import '../../../models/property_model.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/inputs/broker_typeahead_field.dart';
import '../../../widgets/inputs/property_typeahead_field.dart';
import '../../../widgets/toast/app_toast.dart';

class AddLeadDialog extends StatefulWidget {
  final SocialLeadModel? leadToEdit;

  const AddLeadDialog({super.key, this.leadToEdit});

  static Future<SocialLeadModel?> show(BuildContext context, {SocialLeadModel? leadToEdit}) {
    return showDialog<SocialLeadModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddLeadDialog(leadToEdit: leadToEdit),
    );
  }

  @override
  State<AddLeadDialog> createState() => _AddLeadDialogState();
}

class _AddLeadDialogState extends State<AddLeadDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _propertyDetailsController;
  late TextEditingController _notesController;

  String? _selectedBrokerId;
  PropertyModel? _selectedProperty;
  LeadStatus _selectedStatus = LeadStatus.pending;
  bool _isSaving = false;

  bool get isEdit => widget.leadToEdit != null;

  @override
  void initState() {
    super.initState();
    final lead = widget.leadToEdit;
    _nameController = TextEditingController(text: lead?.userName ?? '');
    _phoneController = TextEditingController(text: lead?.phone ?? '');
    _propertyDetailsController = TextEditingController(text: lead?.propertyDetails ?? '');
    _notesController = TextEditingController(text: lead?.notes ?? '');
    _selectedBrokerId = lead?.resolvedBrokerId;
    _selectedStatus = lead?.status ?? LeadStatus.pending;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _propertyDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'leads_val_name_required'.tr();
    }
    if (value.trim().length < 2) {
      return 'leads_val_name_min'.tr();
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'leads_val_phone_required'.tr();
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'leads_val_phone_invalid'.tr();
    }
    return null;
  }

  String? _validatePropertyDetails(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'leads_val_prop_required'.tr();
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBrokerId == null || _selectedBrokerId!.isEmpty) {
      AppToast.showError('error'.tr(), 'leads_dialog_select_broker_hint'.tr());
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AdminLeadsProvider>();

    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final propertyDetails = _propertyDetailsController.text.trim();
    final notes = _notesController.text.trim();

    try {
      if (isEdit) {
        final updatedLead = widget.leadToEdit!.copyWith(
          userName: name,
          phone: rawPhone,
          propertyDetails: propertyDetails,
          notes: notes.isNotEmpty ? notes : null,
          rawBrokerId: _selectedBrokerId,
          status: _selectedStatus,
        );
        final success = await provider.updateLead(updatedLead);
        if (success && mounted) {
          AppToast.showSuccess('leads_toast_updated'.tr());
          Navigator.of(context).pop(updatedLead);
        }
      } else {
        final newLead = await provider.createLead(
          userName: name,
          phone: rawPhone,
          propertyDetails: propertyDetails,
          notes: notes.isNotEmpty ? notes : null,
          brokerId: _selectedBrokerId,
          status: _selectedStatus,
        );
        if (mounted) {
          AppToast.showSuccess('leads_toast_created'.tr());
          Navigator.of(context).pop(newLead);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError('error'.tr(), e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: isEdit ? 'leads_edit_lead'.tr() : 'leads_add_lead_new'.tr(),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Broker as Main Context
            BrokerTypeAheadField(
              selectedBrokerId: _selectedBrokerId,
              onBrokerChanged: (brokerId) {
                setState(() {
                  _selectedBrokerId = brokerId;
                  _selectedProperty = null;
                  _propertyDetailsController.clear();
                });
              },
              label: 'leads_dialog_assign_broker'.tr(),
              hintText: 'leads_dialog_select_broker_hint'.tr(),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // 2. Inquired Property TypeAhead (Filtered strictly by selected broker)
            PropertyTypeAheadField(
              brokerId: _selectedBrokerId,
              controller: _propertyDetailsController,
              selectedPropertyId: _selectedProperty?.id,
              onPropertyChanged: (property) {
                setState(() {
                  _selectedProperty = property;
                });
              },
              validator: _validatePropertyDetails,
              label: 'leads_dialog_property_details'.tr(),
              hintText: 'leads_dialog_property_details_hint'.tr(),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // 3. Client Name
            AppTextField(
              controller: _nameController,
              label: 'leads_dialog_client_name'.tr(),
              hintText: 'leads_dialog_client_name_hint'.tr(),
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: context.primaryColor),
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // 4. Phone Number with +91 Prefix
            AppTextField(
              controller: _phoneController,
              label: 'leads_dialog_mobile_number'.tr(),
              hintText: '9876543210',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.phone_outlined, size: 20, color: context.primaryColor),
                  const SizedBox(width: 8),
                  Text('+91 ', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                  Container(width: 1, height: 16, color: context.borderColor),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Lead Status Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('leads_status'.tr(), style: context.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LeadStatus>(
                      isExpanded: true,
                      value: _selectedStatus,
                      items: LeadStatus.values.map((status) {
                        return DropdownMenuItem<LeadStatus>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(status.icon, size: 16, color: status.color),
                              const SizedBox(width: 10),
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: status.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          setState(() => _selectedStatus = newStatus);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Additional Inquiry Notes
            AppTextField(
              controller: _notesController,
              label: 'leads_dialog_notes_label'.tr(),
              hintText: 'leads_dialog_notes_hint'.tr(),
              maxLines: 2,
              prefixIcon: Icon(Icons.notes_rounded, size: 20, color: context.primaryColor),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outline(
                  text: 'cancel'.tr(),
                  height: 42,
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppButton.solid(
                  text: isEdit ? 'leads_dialog_save_changes'.tr() : 'leads_dialog_create_lead'.tr(),
                  height: 42,
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
