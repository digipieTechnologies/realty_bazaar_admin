// File: lib/modules/properties/screens/property_detail_mobile.dart
// Purpose: Clean Mobile layout for Property Detail screen delegating tab views to modular widgets.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:brokerflow_admin/providers/properties/admin_property_provider.dart';
import 'package:brokerflow_admin/widgets/dialogs/property_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/property_detail_overview_tab.dart';
import '../widgets/property_media_gallery.dart';
import '../widgets/property_posts_tab.dart';

class PropertyDetailMobile extends StatelessWidget {
  final PropertyModel property;
  final AdminPropertyProvider propertiesProv;
  final Future<void> Function() onDelete;

  const PropertyDetailMobile({
    super.key,
    required this.property,
    required this.propertiesProv,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(property.propertyTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                PropertyEditDialog.show(
                  context,
                  property: property,
                  onSave: (updated) => propertiesProv.updateProperty(updated),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              onPressed: () => onDelete(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: [
              Tab(text: 'tab_overview'.tr()),
              Tab(text: 'tab_media'.tr()),
              Tab(text: 'tab_posts'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Overview Tab
            PropertyDetailOverviewTab(property: property),

            // Media Gallery Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: PropertyMediaGallery(medias: property.medias),
            ),

            // Posts Tab
            PropertyPostsTab(propertyId: property.id),
          ],
        ),
      ),
    );
  }
}
