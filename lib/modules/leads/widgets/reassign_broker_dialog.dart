// File: lib/modules/leads/widgets/reassign_broker_dialog.dart
// Purpose: Quick modal dialog for Super Admins to reassign an inquiry to a different broker
// and select a property related to the new broker.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/property_model.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/inputs/broker_typeahead_field.dart';
import '../../../widgets/inputs/property_typeahead_field.dart';
import '../../../widgets/toast/app_toast.dart';

class ReassignBrokerDialog extends StatefulWidget {
  final SocialLeadModel lead;

  const ReassignBrokerDialog({super.key, required this.lead});

  static Future<bool?> show(BuildContext context, SocialLeadModel lead) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReassignBrokerDialog(lead: lead),
    );
  }

  @override
  State<ReassignBrokerDialog> createState() => _ReassignBrokerDialogState();
}

class _ReassignBrokerDialogState extends State<ReassignBrokerDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBrokerId;
  PropertyModel? _selectedProperty;
  late final TextEditingController _propertyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBrokerId = widget.lead.resolvedBrokerId;
    _propertyController = TextEditingController(
      text: widget.lead.propertyDetails ?? widget.lead.socialPost?.property?.propertyTitle ?? '',
    );
  }

  @override
  void dispose() {
    _propertyController.dispose();
    super.dispose();
  }

  Future<void> _handleReassign() async {
    if (_selectedBrokerId == null || _selectedBrokerId!.isEmpty) {
      AppToast.showError('error'.tr(), 'leads_dialog_select_broker_hint'.tr());
      return;
    }

    if (_propertyController.text.trim().isEmpty) {
      AppToast.showError('error'.tr(), 'leads_val_prop_required'.tr());
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AdminLeadsProvider>();

    try {
      final success = await provider.reassignBroker(
        widget.lead.id!,
        _selectedBrokerId,
        propertyDetails: _propertyController.text.trim(),
      );
      if (success && mounted) {
        AppToast.showSuccess('leads_toast_reassigned'.tr());
        Navigator.of(context).pop(true);
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
    final currentBrokerName = widget.lead.broker?.businessName ?? 'leads_unassigned'.tr();
    final currentPropertyName = widget.lead.propertyDetails?.trim().isNotEmpty == true
        ? widget.lead.propertyDetails!.trim()
        : (widget.lead.socialPost?.property?.propertyTitle ?? widget.lead.socialPost?.caption ?? '--');

    return AppDialog(
      title: 'leads_reassign_broker'.tr(),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Assignment Summary Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  // Broker Row
                  Row(
                    children: [
                      Icon(Icons.business_rounded, size: 18, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'leads_dialog_current_broker'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentBrokerName,
                          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Property Row
                  Row(
                    children: [
                      Icon(Icons.apartment_rounded, size: 18, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'leads_col_property'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentPropertyName,
                          style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Select New Broker TypeAhead
            BrokerTypeAheadField(
              selectedBrokerId: _selectedBrokerId,
              onBrokerChanged: (brokerId) {
                setState(() {
                  _selectedBrokerId = brokerId;
                  _selectedProperty = null;
                  _propertyController.clear();
                });
              },
              label: 'leads_dialog_select_new_broker'.tr(),
              hintText: 'leads_dialog_select_broker_hint'.tr(),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // 2. Select Property for New Broker
            PropertyTypeAheadField(
              brokerId: _selectedBrokerId,
              controller: _propertyController,
              selectedPropertyId: _selectedProperty?.id,
              onPropertyChanged: (property) {
                setState(() {
                  _selectedProperty = property;
                });
              },
              label: 'leads_dialog_property_details'.tr(),
              hintText: 'leads_dialog_property_details_hint'.tr(),
              isRequired: true,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outline(
                  text: 'cancel'.tr(),
                  height: 40,
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppButton.solid(
                  text: 'leads_reassign_broker'.tr(),
                  height: 40,
                  isLoading: _isSaving,
                  onPressed: _handleReassign,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
