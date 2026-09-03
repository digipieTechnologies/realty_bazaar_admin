// File: lib/modules/brokers/widgets/broker_detail_sidebar_card.dart
// Purpose: Reusable master sidebar card for Broker Detail desktop screen.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/broker_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BrokerDetailSidebarCard extends StatelessWidget {
  final BrokerModel broker;

  const BrokerDetailSidebarCard({super.key, required this.broker});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isActive = broker.isActive ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          broker.avatarImage(context: context, width: 40, height: 40),
          const SizedBox(height: 16),
          Text(
            broker.businessName ?? '-',
            style: context.pageTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('ID: ${broker.id ?? '-'}', style: context.cardSubtitle.copyWith(fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.primary : AppColors.textMuted).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isActive ? AppColors.primary : AppColors.textMuted).withOpacity(0.2),
              ),
            ),
            child: Text(
              isActive ? 'status_active'.tr() : 'status_inactive'.tr(),
              style: context.badgeText.copyWith(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          const Divider(height: 32),

          // Business Meta Info
          _buildSidebarRow(context, colorScheme, Icons.stars_outlined, 'plan'.tr(), broker.plan ?? 'Free'),
          const SizedBox(height: 12),
          _buildSidebarRow(
            context,
            colorScheme,
            Icons.speed_outlined,
            'onboarding_status'.tr(),
            (broker.onboardingStatus ?? 'pending').toUpperCase(),
          ),
          const SizedBox(height: 12),
          _buildSidebarRow(
            context,
            colorScheme,
            Icons.location_on_outlined,
            'address'.tr(),
            broker.addressId != null
                ? (broker.addressId?.fullAddress?.isNotEmpty == true
                      ? broker.addressId!.fullAddress!
                      : '${broker.addressId?.city ?? ''}, ${broker.addressId?.state ?? ''}')
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarRow(
    BuildContext context,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.cardSubtitle.copyWith(fontSize: 11)),
              Text(value, style: context.cardTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
