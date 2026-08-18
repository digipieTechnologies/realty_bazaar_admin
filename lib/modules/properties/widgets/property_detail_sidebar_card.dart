// File: lib/modules/properties/widgets/property_detail_sidebar_card.dart
// Purpose: Reusable master sidebar card for Property Detail desktop screen.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_enums.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PropertyDetailSidebarCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailSidebarCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: property.propertyImage(context: context, width: double.infinity, height: 180),
          ),
          const SizedBox(height: 16),
          Text(property.propertyTitle, style: context.pageTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            property.price.formatCurrency,
            style: context.pageTitle.copyWith(fontSize: 22, color: AppColors.primary),
          ),
          const SizedBox(height: 12),

          // Status & Type Pills Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(context, property.propertyStatus.displayName, AppColors.primary),
              _buildBadge(context, property.listingType.displayName, AppColors.secondary),
              _buildBadge(context, property.propertyType.displayName, colorScheme.onSurfaceVariant),
            ],
          ),
          const Divider(height: 32),

          // Key Specs Grid
          _buildSpecRow(
            context,
            colorScheme,
            Icons.square_foot_rounded,
            '${property.area} ${property.areaUnit.displayName}',
          ),
          const SizedBox(height: 12),
          _buildSpecRow(context, colorScheme, Icons.bed_outlined, '${property.bedrooms} Bedrooms'),
          const SizedBox(height: 12),
          _buildSpecRow(context, colorScheme, Icons.bathtub_outlined, '${property.bathrooms} Bathrooms'),
          const SizedBox(height: 12),
          _buildSpecRow(context, colorScheme, Icons.directions_car_outlined, '${property.parking} Parking'),
          const SizedBox(height: 12),
          _buildSpecRow(context, colorScheme, Icons.chair_outlined, property.furnishingStatus.displayName),
          const Divider(height: 32),

          // Broker Info Section Card
          _buildBrokerInfoCard(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBrokerInfoCard(BuildContext context, ColorScheme colorScheme) {
    final broker = property.broker;
    final brokerId = property.brokerId ?? broker?.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'broker_information'.tr(),
                style: context.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (broker != null)
                broker.avatarImage(radius: 20, iconSize: 20)
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broker?.businessName ?? 'Broker ID: ${brokerId ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (broker?.plan != null)
                      Text(
                        '${broker!.plan} Plan',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (brokerId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/brokers/detail/$brokerId'),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('view_broker'.tr(), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
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

  Widget _buildSpecRow(BuildContext context, ColorScheme colorScheme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: context.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
