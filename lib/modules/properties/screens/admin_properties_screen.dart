// File: lib/modules/properties/screens/admin_properties_screen.dart
// Purpose: Super Admin Properties catalog screen. Owns state and delegates UI layout to PropertiesDesktop or PropertiesMobile.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/filters/filter_provider.dart';
import '../../../models/models.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/property_filter_model.dart';
import 'properties_desktop.dart';
import 'properties_mobile.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => AdminPropertiesScreenState();
}

class AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  late final FilterProvider<PropertyFilterModel> filterProvider;
  bool showFilterSidebar = false;

  AdminPropertyProvider get propertyProv => context.watch<AdminPropertyProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<PropertyFilterModel>(
      definition: PropertyFilterModel.filterDefinition,
      initialFilters: const PropertyFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        context.read<AdminPropertyProvider>().updateFilter(active);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminPropertyProvider>().fetchProperties();
    });
  }

  @override
  void dispose() {
    filterProvider.dispose();
    super.dispose();
  }

  void toggleFilterSidebar() {
    setState(() {
      showFilterSidebar = !showFilterSidebar;
    });
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterpriseFilterPanel(
        provider: filterProvider,
        isSidebar: false,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> confirmAndDeleteProperty(PropertyModel property) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'Delete Property',
      message:
          'Are you sure you want to delete ${property.propertyTitle}? This will remove it from the active catalog.',
      confirmLabel: 'Delete Property',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      final success = await context.read<AdminPropertyProvider>().deleteProperty(property.id!);
      if (success && mounted) {
        AppToast.showSuccess('Property Deleted', 'Removed from active catalog.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return PropertiesDesktop(state: this);
    }
    return PropertiesMobile(state: this);
  }
}
