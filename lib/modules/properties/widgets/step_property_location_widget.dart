// File: lib/modules/properties/widgets/step_property_location_widget.dart
// Purpose: Step 3 Location form with Admin Broker selector for assigning/switching broker.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/inputs/app_textfield.dart';
import '../../../widgets/inputs/broker_typeahead_field.dart';
import 'field_info_dialog.dart';

class StepPropertyLocationWidget extends StatelessWidget {
  final TextEditingController fullAddressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController pincodeController;
  final TextEditingController landmarkController;
  final String? selectedBrokerId;
  final ValueChanged<String?> onBrokerChanged;

  const StepPropertyLocationWidget({
    super.key,
    required this.fullAddressController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.pincodeController,
    required this.landmarkController,
    required this.selectedBrokerId,
    required this.onBrokerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. BROKER ASSIGNMENT SECTION (Admin specific)
        Row(
          children: [
            Flexible(
              child: Text(
                'Broker Association',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  FieldInfoDialog.show(
                    context,
                    title: 'property_broker_association_title'.tr(),
                    description: 'property_broker_association_desc'.tr(),
                    examples: [
                      'property_broker_association_ex1'.tr(),
                      'property_broker_association_ex2'.tr(),
                    ],
                  );
                },
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'property_broker_select_subtitle'.tr(),
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14.0),

        BrokerTypeAheadField(
          selectedBrokerId: selectedBrokerId,
          onBrokerChanged: onBrokerChanged,
          isRequired: true,
        ),
        const SizedBox(height: 36.0),

        // 2. LOCATION DETAILS SECTION
        Row(
          children: [
            Flexible(
              child: Text(
                'section_location_details'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  FieldInfoDialog.show(
                    context,
                    title: 'section_location_details'.tr(),
                    description: 'location_subtitle'.tr(),
                    examples: const [
                      'Street Address: 521, Royal Empress, Near Dumas Beach Road',
                      'City: Surat, State: Gujarat',
                      'Landmark: Opposite Model Town Circle',
                    ],
                    tip: 'Including a recognizable landmark increases buyer viewing inquiries by 35%.',
                  );
                },
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'location_subtitle'.tr(),
          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18.0),

        // Full Address Line Input
        AppTextField(
          controller: fullAddressController,
          label: '${'street_address_label'.tr()} *',
          hintText: 'street_address_hint'.tr(),
          maxLines: 1,
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
        const SizedBox(height: 14.0),

        // Landmark Input
        AppTextField(
          controller: landmarkController,
          label: 'landmark'.tr(),
          hintText: 'landmark_hint'.tr(),
          prefixIcon: const Icon(Icons.near_me_outlined),
        ),
        const SizedBox(height: 14.0),

        // City & State Inputs
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: cityController,
                label: '${'city'.tr()} *',
                hintText: 'city_hint'.tr(),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: AppTextField(
                controller: stateController,
                label: '${'state'.tr()} *',
                hintText: 'state_hint'.tr(),
                prefixIcon: const Icon(Icons.map_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),

        // Country & Pincode Inputs
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: countryController,
                label: '${'country'.tr()} *',
                hintText: 'country_hint'.tr(),
                prefixIcon: const Icon(Icons.public_outlined),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: AppTextField(
                controller: pincodeController,
                label: '${'pincode'.tr()} *',
                hintText: 'pincode_hint'.tr(),
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.pin_drop_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
