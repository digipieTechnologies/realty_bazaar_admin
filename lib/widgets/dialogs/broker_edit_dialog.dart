// File: lib/widgets/dialogs/broker_edit_dialog.dart
// Purpose: Modal dialog for editing Broker subscription plan, onboarding status, and location address details.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../models/broker_model.dart';
import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class BrokerEditDialog extends StatefulWidget {
  final BrokerModel broker;
  final ValueChanged<BrokerModel> onSave;

  const BrokerEditDialog({super.key, required this.broker, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    required BrokerModel broker,
    required ValueChanged<BrokerModel> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BrokerEditDialog(broker: broker, onSave: onSave),
    );
  }

  @override
  State<BrokerEditDialog> createState() => _BrokerEditDialogState();
}

class _BrokerEditDialogState extends State<BrokerEditDialog> {
  late TextEditingController _businessNameController;
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _landmarkController;

  late String _plan;
  late String _onboardingStatus;
  late bool _isActive;
  late bool _autoApproveVideoRequests;

  @override
  void initState() {
    super.initState();
    final address = widget.broker.addressId;
    _businessNameController = TextEditingController(text: widget.broker.businessName);
    _fullAddressController = TextEditingController(text: address?.fullAddress ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _pincodeController = TextEditingController(text: address?.pincode ?? '');
    _countryController = TextEditingController(text: address?.country ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');

    _plan = widget.broker.plan ?? 'Free';
    _onboardingStatus = widget.broker.onboardingStatus ?? 'pending';
    _isActive = widget.broker.isActive ?? true;
    _autoApproveVideoRequests = widget.broker.autoApproveVideoRequests ?? false;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'brokers_edit_broker_title'.tr(),
      content: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'brokers_business_info'.tr(),
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            AppTextField(label: 'business_name'.tr(), controller: _businessNameController),

            CustomizedDropdown<String>(
              label: 'plan'.tr(),
              value: _plan,
              enableSearch: false,
              items: const ['Free', 'Pro', 'Enterprise'],
              showAllOption: false,
              displayValue: (plan) => '$plan Tier',
              onChanged: (val) {
                if (val != null) setState(() => _plan = val);
              },
            ),

            CustomizedDropdown<String>(
              label: 'onboarding_status'.tr(),
              value: _onboardingStatus,
              enableSearch: false,
              items: const ['pending', 'completed', 'rejected'],
              showAllOption: false,
              displayValue: (status) {
                switch (status) {
                  case 'pending':
                    return 'status_pending'.tr();
                  case 'completed':
                    return 'status_active'.tr();
                  case 'rejected':
                    return 'status_deleted'.tr();
                  default:
                    return status;
                }
              },
              onChanged: (val) {
                if (val != null) setState(() => _onboardingStatus = val);
              },
            ),

            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('broker_active'.tr()),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('auto_approve_video_requests'.tr()),
                value: _autoApproveVideoRequests,
                onChanged: (val) => setState(() => _autoApproveVideoRequests = val),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const Divider(color: AppColors.border),
            Text('address_details'.tr(), style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),

            AppTextField(label: 'full_address'.tr(), controller: _fullAddressController, maxLines: 2),

            Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'city'.tr(), controller: _cityController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(label: 'state'.tr(), controller: _stateController),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: AppTextField(label: 'pincode'.tr(), controller: _pincodeController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(label: 'country'.tr(), controller: _countryController),
                ),
              ],
            ),

            AppTextField(label: 'landmark'.tr(), controller: _landmarkController),
          ],
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(
          text: 'save'.tr(),
          onPressed: () {
            final updatedAddress = AddressModel(
              id: widget.broker.addressId?.id,
              fullAddress: _fullAddressController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              pincode: _pincodeController.text.trim(),
              country: _countryController.text.trim(),
              landmark: _landmarkController.text.trim(),
              entityType: 'broker',
              entityId: widget.broker.id,
            );

            final updated = widget.broker.copyWith(
              businessName: _businessNameController.text.trim(),
              plan: _plan,
              onboardingStatus: _onboardingStatus,
              isActive: _isActive,
              autoApproveVideoRequests: _autoApproveVideoRequests,
              addressId: updatedAddress,
            );
            widget.onSave(updated);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
