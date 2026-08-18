// File: lib/modules/properties/widgets/property_detail_overview_tab.dart
// Purpose: Mobile Overview Tab child widget for Property Details screen matching broker app layout with AutomaticKeepAliveClientMixin and TabHeader.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_enums.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:brokerflow_admin/providers/properties/admin_property_provider.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
            const SizedBox(height: 16),
          ],

          // Location Card
          if (property.address != null) ...[
            _buildSectionCard(
              context,
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
      _MobileDetailItem(
        Icons.sell_outlined,
        'properties_listing_type'.tr(),
        property.listingType.displayName,
      ),
      _MobileDetailItem(Icons.verified_outlined, 'status'.tr(), property.propertyStatus.displayName),
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
