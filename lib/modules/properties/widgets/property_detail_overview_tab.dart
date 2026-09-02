// File: lib/modules/properties/widgets/property_detail_overview_tab.dart
// Purpose: Mobile Overview Tab child widget for Property Details screen matching broker app layout with quick feature counters, PropertyAmenitiesWrap, and PropertyLocationCard.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/common_ext.dart';
import '../../../app/context_ext.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/tab_header.dart';
import 'property_amenities_wrap.dart';
import 'property_location_card.dart';

class PropertyDetailOverviewTab extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailOverviewTab({super.key, required this.property});

  @override
  State<PropertyDetailOverviewTab> createState() => _PropertyDetailOverviewTabState();
}

class _PropertyDetailOverviewTabState extends State<PropertyDetailOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colorScheme;
    final property = widget.property;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(
            title: 'properties_overview'.tr(),
            padding: const EdgeInsets.only(bottom: 12),
            onRefresh: () {
              context.read<AdminPropertyProvider>().refresh();
            },
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: property.propertyImage(context: context, width: double.infinity, height: 220),
          ),
          const SizedBox(height: 16),

          // Title & Price Section
          Text(property.propertyTitle, style: context.pageTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            property.price.formatCurrency,
            style: context.pageSubtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMobileBadge(context, property.propertyType.displayName, AppColors.primary),
              _buildMobileBadge(context, property.listingType.displayName, AppColors.secondary),
              _buildMobileBadge(context, property.constructionStatus.displayName, Colors.green),
              _buildMobileBadge(context, property.propertyStatus.displayName, colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Feature Grid
          _buildQuickFeatureTiles(context, property),
          const SizedBox(height: 16),

          // Description
          if (property.propertyDescription != null && property.propertyDescription!.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  property.propertyDescription!,
                  style: context.cardSubtitle.copyWith(fontSize: 14, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Specifications Card
          _buildSectionCard(context, title: 'specifications'.tr(), child: _buildSpecsGrid(context)),
          const SizedBox(height: 16),

          // Property Details Card
          _buildSectionCard(
            context,
            title: 'property_details_title'.tr(),
            child: _buildPropertyDetailsList(context),
          ),
          const SizedBox(height: 16),

          // Facilities & Amenities Card
          if (property.amenities.isNotEmpty) ...[
            _buildSectionCard(
              context,
              title: 'facilities_amenities'.tr(),
              child: PropertyAmenitiesWrap(amenities: property.amenities),
            ),
            const SizedBox(height: 16),
          ],

          // Location Card
          if (property.address != null) ...[
            _buildSectionCard(
              context,
              title: 'location'.tr(),
              child: PropertyLocationCard(address: property.address),
            ),
            const SizedBox(height: 16),
          ],

          // Broker Information Card
          _buildSectionCard(
            context,
            title: 'broker_information'.tr(),
            child: _buildBrokerDetailCard(context),
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
      _MobileFeatureTileData(icon: Icons.bed_outlined, label: 'property_spec_bedrooms'.tr().toUpperCase(), value: '${property.bedrooms} BHK'),
      _MobileFeatureTileData(icon: Icons.bathtub_outlined, label: 'property_spec_bathrooms'.tr().toUpperCase(), value: '${property.bathrooms} Baths'),
      _MobileFeatureTileData(icon: Icons.balcony_outlined, label: 'property_spec_balconies'.tr().toUpperCase(), value: '${property.balconies} Balconies'),
      _MobileFeatureTileData(icon: Icons.apartment_outlined, label: 'property_spec_floor'.tr().toUpperCase(), value: floorText),
      _MobileFeatureTileData(icon: Icons.domain_outlined, label: 'property_spec_property_type'.tr().toUpperCase(), value: property.propertyType.displayName),
      _MobileFeatureTileData(icon: Icons.key_outlined, label: 'property_spec_possession'.tr().toUpperCase(), value: possessionText),
      _MobileFeatureTileData(icon: Icons.explore_outlined, label: 'property_spec_facing'.tr().toUpperCase(), value: facingText),
      _MobileFeatureTileData(icon: Icons.directions_car_outlined, label: 'property_spec_parking'.tr().toUpperCase(), value: '${property.parking} Reserved'),
    ];

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 540.0 ? 4 : 2;
          const spacing = 8.0;
          final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles.map((tile) {
              return SizedBox(
                width: itemWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Icon(tile.icon, color: const Color(0xFF3B82F6), size: 14.0),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tile.label,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1.0),
                            Text(
                              tile.value,
                              style: const TextStyle(
                                fontSize: 11.5,
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
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildBrokerDetailCard(BuildContext context) {
    final colorScheme = context.colorScheme;
    final broker = widget.property.broker;
    final brokerId = widget.property.brokerId ?? broker?.id;

    return Row(
      children: [
        if (broker != null)
          broker.avatarImage(radius: 24, iconSize: 24)
        else
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                broker?.businessName ?? 'Broker ID: ${brokerId ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (broker?.plan != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${broker!.plan} Plan • ${broker.onboardingStatus?.toUpperCase() ?? 'PENDING'}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (brokerId != null)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: () => context.go('/brokers/detail/$brokerId'),
            tooltip: 'view_broker'.tr(),
          ),
      ],
    );
  }

  Widget _buildMobileBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child}) {
    final colorScheme = context.colorScheme;
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

  Widget _buildSpecsGrid(BuildContext context) {
    final colorScheme = context.colorScheme;
    final property = widget.property;
    final specs = [
      _MobileSpecItem(Icons.bed_rounded, 'bedrooms'.tr(), '${property.bedrooms} BHK'),
      _MobileSpecItem(Icons.bathroom_rounded, 'bathrooms'.tr(), '${property.bathrooms} Baths'),
      _MobileSpecItem(Icons.balcony_rounded, 'balconies'.tr(), '${property.balconies} Balconies'),
      _MobileSpecItem(
        Icons.square_foot_rounded,
        'super_area'.tr(),
        '${property.area.toStringAsFixed(0)} ${property.areaUnit.displayName}',
      ),
      _MobileSpecItem(Icons.explore_outlined, 'facing'.tr(), property.facing?.displayName ?? 'N/A'),
      _MobileSpecItem(Icons.local_parking_rounded, 'parking_slots'.tr(), '${property.parking} Vehicles'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specs.map((s) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            s.value,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPropertyDetailsList(BuildContext context) {
    final colorScheme = context.colorScheme;
    final property = widget.property;
    final details = [
      _MobileDetailItem(Icons.chair_outlined, 'furnishing'.tr(), property.furnishingStatus.displayName),
      _MobileDetailItem(
        Icons.construction_outlined,
        'construction'.tr(),
        property.constructionStatus.displayName,
      ),
      if (property.floorNumber != null)
        _MobileDetailItem(
          Icons.layers_outlined,
          'floor'.tr(),
          property.totalFloors != null
              ? '${property.floorNumber} of ${property.totalFloors}'
              : '${property.floorNumber}',
        ),
      _MobileDetailItem(Icons.category_outlined, 'type'.tr(), property.propertyType.displayName),
      _MobileDetailItem(Icons.sell_outlined, 'properties_listing_type'.tr(), property.listingType.displayName),
      _MobileDetailItem(Icons.verified_outlined, 'status'.tr(), property.propertyStatus.displayName),
    ];

    return Column(
      children: details.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(d.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(d.label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ),
              Text(d.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MobileFeatureTileData {
  final IconData icon;
  final String label;
  final String value;

  _MobileFeatureTileData({required this.icon, required this.label, required this.value});
}

class _MobileSpecItem {
  final IconData icon;
  final String label;
  final String value;

  _MobileSpecItem(this.icon, this.label, this.value);
}

class _MobileDetailItem {
  final IconData icon;
  final String label;
  final String value;

  _MobileDetailItem(this.icon, this.label, this.value);
}
