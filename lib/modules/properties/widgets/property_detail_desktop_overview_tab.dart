// File: lib/modules/properties/widgets/property_detail_desktop_overview_tab.dart
// Purpose: Desktop Overview Tab child widget for Property Details screen matching broker app layout with AutomaticKeepAliveClientMixin and TabHeader.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_enums.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:brokerflow_admin/providers/properties/admin_property_provider.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PropertyDetailDesktopOverviewTab extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailDesktopOverviewTab({super.key, required this.property});

  @override
  State<PropertyDetailDesktopOverviewTab> createState() => _PropertyDetailDesktopOverviewTabState();
}

class _PropertyDetailDesktopOverviewTabState extends State<PropertyDetailDesktopOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colorScheme;
    final property = widget.property;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(
            title: 'properties_overview'.tr(),
            padding: const EdgeInsets.only(bottom: 0),
            onRefresh: () {
              context.read<AdminPropertyProvider>().refresh();
            },
          ),

          if (property.propertyDescription != null && property.propertyDescription!.isNotEmpty) ...[
            Text(
              property.propertyDescription ?? 'no_data'.tr(),
              style: context.cardSubtitle.copyWith(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),

          // Specifications Section Card
          _buildDesktopSectionCard(
            context,
            colorScheme,
            title: 'specifications'.tr(),
            child: _buildDesktopSpecsGrid(context, colorScheme),
          ),
          const SizedBox(height: 20),

          // Property Details Section Card
          _buildDesktopSectionCard(
            context,
            colorScheme,
            title: 'property_details_title'.tr(),
            child: _buildDesktopPropertyDetailsList(context, colorScheme),
          ),
          const SizedBox(height: 20),

          // Amenities Section
          if (property.amenities.isNotEmpty) ...[
            _buildDesktopSectionCard(
              context,
              colorScheme,
              title: 'facilities_amenities'.tr(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: property.amenities
                    .map(
                      (a) => Chip(
                        label: Text(a),
                        backgroundColor: colorScheme.primaryContainer.withOpacity(0.4),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Location Section
          if (property.address != null) ...[
            _buildDesktopSectionCard(
              context,
              colorScheme,
              title: 'location'.tr(),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      [
                        property.address?.fullAddress,
                        property.address?.city,
                        property.address?.state,
                        property.address?.pincode,
                      ].where((e) => e != null && e.isNotEmpty).join(', '),
                      style: context.cardSubtitle.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Broker Information Section Card
          _buildDesktopSectionCard(
            context,
            colorScheme,
            title: 'broker_information'.tr(),
            child: _buildDesktopBrokerDetailCard(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBrokerDetailCard(BuildContext context, ColorScheme colorScheme) {
    final broker = widget.property.broker;
    final brokerId = widget.property.brokerId ?? broker?.id;

    return Row(
      children: [
        if (broker != null)
          broker.avatarImage(radius: 26, iconSize: 26)
        else
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 26),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                broker?.businessName ?? 'Broker ID: ${brokerId ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (broker?.plan != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${broker!.plan} Plan • ${broker.onboardingStatus?.toUpperCase() ?? 'PENDING'}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        if (brokerId != null)
          ElevatedButton.icon(
            onPressed: () => context.go('/brokers/detail/$brokerId'),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text('view_broker'.tr()),
          ),
      ],
    );
  }

  Widget _buildDesktopSectionCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDesktopSpecsGrid(BuildContext context, ColorScheme colorScheme) {
    final property = widget.property;
    final specs = [
      _SpecData(Icons.bed_rounded, 'bedrooms'.tr(), '${property.bedrooms} BHK'),
      _SpecData(Icons.bathroom_rounded, 'bathrooms'.tr(), '${property.bathrooms} Baths'),
      _SpecData(Icons.balcony_rounded, 'balconies'.tr(), '${property.balconies} Balconies'),
      _SpecData(
        Icons.square_foot_rounded,
        'super_area'.tr(),
        '${property.area.toStringAsFixed(0)} ${property.areaUnit.displayName}',
      ),
      _SpecData(Icons.explore_outlined, 'facing'.tr(), property.facing?.displayName ?? 'N/A'),
      _SpecData(Icons.local_parking_rounded, 'parking_slots'.tr(), '${property.parking} Vehicles'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: specs.map((s) {
        return Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(s.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(s.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopPropertyDetailsList(BuildContext context, ColorScheme colorScheme) {
    final property = widget.property;
    final details = [
      _DetailData(Icons.chair_outlined, 'furnishing'.tr(), property.furnishingStatus.displayName),
      _DetailData(Icons.construction_outlined, 'construction'.tr(), property.constructionStatus.displayName),
      if (property.floorNumber != null)
        _DetailData(
          Icons.layers_outlined,
          'floor'.tr(),
          property.totalFloors != null
              ? '${property.floorNumber} of ${property.totalFloors}'
              : '${property.floorNumber}',
        ),
      _DetailData(Icons.category_outlined, 'type'.tr(), property.propertyType.displayName),
      _DetailData(Icons.sell_outlined, 'properties_listing_type'.tr(), property.listingType.displayName),
      _DetailData(Icons.verified_outlined, 'status'.tr(), property.propertyStatus.displayName),
    ];

    return Column(
      children: details.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(d.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(d.label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
              Text(d.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SpecData {
  final IconData icon;
  final String label;
  final String value;

  _SpecData(this.icon, this.label, this.value);
}

class _DetailData {
  final IconData icon;
  final String label;
  final String value;

  _DetailData(this.icon, this.label, this.value);
}
