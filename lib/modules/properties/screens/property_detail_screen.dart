// File: lib/modules/properties/screens/property_detail_screen.dart
// Purpose: Responsive entry controller for Property Detail screen.

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../models/property_model.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import 'property_detail_desktop.dart';
import 'property_detail_mobile.dart';

class PropertyDetailScreen extends StatelessWidget {
  final PropertyModel? property;
  final String? propertyId;

  const PropertyDetailScreen({super.key, this.property, this.propertyId});

  @override
  Widget build(BuildContext context) {
    final propertiesProv = context.watch<AdminPropertyProvider>();
    final targetProperty = property ?? propertiesProv.properties.firstWhereOrNull((p) => p.id == propertyId);

    final colorScheme = context.colorScheme;

    if (targetProperty == null) {
      return Scaffold(
        appBar: AppBar(title: Text('properties_details'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('no_data'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: Text('cancel'.tr())),
            ],
          ),
        ),
      );
    }

    Future<void> onDeleteProperty() async {
      final confirmed = await ConfirmDialog.showResponsive(
        context: context,
        title: 'properties_delete_title'.tr(),
        message: 'properties_delete_confirm'.tr(namedArgs: {'title': targetProperty.propertyTitle}),
        confirmLabel: 'delete'.tr(),
        cancelLabel: 'cancel'.tr(),
        isDestructive: true,
      );
      if (confirmed == true && context.mounted) {
        propertiesProv.deleteProperty(targetProperty.id!);
        AppToast.showSuccess('properties_delete_success'.tr());
        context.pop();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: context.isDesktop
          ? PropertyDetailDesktop(
              property: targetProperty,
              propertiesProv: propertiesProv,
              onDelete: onDeleteProperty,
            )
          : PropertyDetailMobile(
              property: targetProperty,
              propertiesProv: propertiesProv,
              onDelete: onDeleteProperty,
            ),
    );
  }
}
