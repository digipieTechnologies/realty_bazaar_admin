// File: lib/modules/properties/screens/property_detail_desktop.dart
// Purpose: Clean Desktop view for Property Detail screen delegating layout children to modular widgets.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:brokerflow_admin/providers/properties/admin_property_provider.dart';
import 'package:brokerflow_admin/widgets/common/app_breadcrumbs.dart';
import 'package:brokerflow_admin/widgets/dialogs/property_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/property_detail_desktop_overview_tab.dart';
import '../widgets/property_detail_sidebar_card.dart';
import '../widgets/property_media_gallery.dart';
import '../widgets/property_posts_tab.dart';

class PropertyDetailDesktop extends StatefulWidget {
  final PropertyModel property;
  final AdminPropertyProvider propertiesProv;
  final Future<void> Function() onDelete;

  const PropertyDetailDesktop({
    super.key,
    required this.property,
    required this.propertiesProv,
    required this.onDelete,
  });

  @override
  State<PropertyDetailDesktop> createState() => _PropertyDetailDesktopState();
}

class _PropertyDetailDesktopState extends State<PropertyDetailDesktop> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final property = widget.property;

    return Column(
      children: [
        // Top Header Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/properties'),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBreadcrumbs(
                      padding: EdgeInsets.zero,
                      items: [
                        BreadcrumbItem(label: 'properties'.tr(), route: '/properties'),
                        BreadcrumbItem(label: property.id ?? 'properties_details'.tr()),
                      ],
                    ),
                    Text(property.propertyTitle, style: context.appBarTitle),
                  ],
                ),
              ),
              // Top Right Actions Toolbar
              OutlinedButton.icon(
                onPressed: () => widget.onDelete(),
                icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 18),
                label: Text('properties_delete_property'.tr(), style: TextStyle(color: colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  PropertyEditDialog.show(
                    context,
                    property: property,
                    onSave: (updated) => widget.propertiesProv.updateProperty(updated),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('properties_edit_property'.tr()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Tab Bar Header Navigation
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'tab_overview'.tr()),
              Tab(text: 'tab_media'.tr()),
              Tab(text: 'tab_posts'.tr()),
            ],
          ),
        ),

        const Divider(height: 1),

        // Main Desktop Two-Column Split Body Layout
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Master Sidebar Card
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(child: PropertyDetailSidebarCard(property: property)),
                ),
                const SizedBox(width: 24),

                // Right Column - Tab Panes Content Area
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20).copyWith(top: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        PropertyDetailDesktopOverviewTab(property: property),
                        PropertyMediaGallery(medias: property.medias),
                        PropertyPostsTab(propertyId: property.id),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
