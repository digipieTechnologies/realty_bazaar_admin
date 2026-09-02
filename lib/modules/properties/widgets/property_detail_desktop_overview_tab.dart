// File: lib/modules/properties/widgets/property_detail_desktop_overview_tab.dart
// Purpose: Desktop Overview Tab child widget for Property Details screen with rich specs, quick feature tiles, visual amenities, location card, and broker assignment matching broker app fidelity.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/tab_header.dart';
import 'property_amenities_wrap.dart';
import 'property_location_card.dart';

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
          const SizedBox(height: 16),

          // 1. Quick Feature Grid
          _buildQuickFeatureTiles(context, property),
          const SizedBox(height: 20),

          // 2. Specifications Section Card
          _buildDesktopSectionCard(
            context,
            colorScheme,
            title: 'specifications'.tr(),
            child: _buildDesktopSpecsGrid(context, colorScheme),
          ),
          const SizedBox(height: 20),

          // 3. Description
          if (property.propertyDescription != null && property.propertyDescription!.trim().isNotEmpty) ...[
            _buildDesktopSectionCard(
              context,
              colorScheme,
              title: 'property_about_title'.tr(),
              child: Text(
                property.propertyDescription!,
                style: context.cardSubtitle.copyWith(fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4. Property Details List
          _buildDesktopSectionCard(
            context,
            colorScheme,
            title: 'property_details_title'.tr(),
            child: _buildDesktopPropertyDetailsList(context, colorScheme),
          ),
          const SizedBox(height: 20),

          // 5. Amenities Section
          if (property.amenities.isNotEmpty) ...[
            _buildDesktopSectionCard(
              context,
              colorScheme,
              title: 'facilities_amenities'.tr(),
              child: PropertyAmenitiesWrap(amenities: property.amenities),
            ),
            const SizedBox(height: 20),
          ],

          // 6. Location Section
          if (property.address != null) ...[
            _buildDesktopSectionCard(
              context,
              colorScheme,
              title: 'location'.tr(),
              child: PropertyLocationCard(address: property.address),
            ),
            const SizedBox(height: 20),
          ],

          // 7. Broker Information Section Card
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

  Widget _buildQuickFeatureTiles(BuildContext context, PropertyModel property) {
    final floorText = property.floorNumber != null
        ? '${property.floorNumber}th of ${property.totalFloors ?? 1} Floors'
        : (property.totalFloors != null ? '${property.totalFloors} Floors' : '1st Floor');

    final facingText = property.facing != null
        ? '${property.facing!.displayName} Facing'
        : 'North East Facing';

    final possessionText = property.constructionStatus == ConstructionStatus.readyToMove
        ? 'Ready To Move'
        : 'Under Construction';

    final tiles = [
      _FeatureTileData(icon: Icons.bed_outlined, label: 'property_spec_bedrooms'.tr().toUpperCase(), value: '${property.bedrooms} BHK'),
      _FeatureTileData(icon: Icons.bathtub_outlined, label: 'property_spec_bathrooms'.tr().toUpperCase(), value: '${property.bathrooms} Baths'),
      _FeatureTileData(icon: Icons.balcony_outlined, label: 'property_spec_balconies'.tr().toUpperCase(), value: '${property.balconies} Balconies'),
      _FeatureTileData(icon: Icons.apartment_outlined, label: 'property_spec_floor'.tr().toUpperCase(), value: floorText),
      _FeatureTileData(icon: Icons.domain_outlined, label: 'property_spec_property_type'.tr().toUpperCase(), value: property.propertyType.displayName),
      _FeatureTileData(icon: Icons.key_outlined, label: 'property_spec_possession'.tr().toUpperCase(), value: possessionText),
      _FeatureTileData(icon: Icons.explore_outlined, label: 'property_spec_facing'.tr().toUpperCase(), value: facingText),
      _FeatureTileData(icon: Icons.directions_car_outlined, label: 'property_spec_parking'.tr().toUpperCase(), value: '${property.parking} Reserved'),
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700.0 ? 4 : 2;
          const spacing = 10.0;
          final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles.map((tile) {
              return SizedBox(
                width: itemWidth,
                child: _buildFeatureTileItem(
                  icon: tile.icon,
                  label: tile.label,
                  value: tile.value,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFeatureTileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 16.0),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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

class _FeatureTileData {
  final IconData icon;
  final String label;
  final String value;

  _FeatureTileData({required this.icon, required this.label, required this.value});
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
