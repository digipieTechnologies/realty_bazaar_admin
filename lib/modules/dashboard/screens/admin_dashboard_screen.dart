// File: lib/modules/dashboard/screens/admin_dashboard_screen.dart
// Purpose: Super Admin overview metrics screen.

import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/dashboard/admin_dashboard_provider.dart';
import '../../../widgets/shimmer/admin_shimmer_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().fetchDashboardSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProv = context.watch<AdminDashboardProvider>();
    final summary = dashboardProv.summary;

    if (dashboardProv.isLoading) {
      return const AdminShimmerWidget();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('welcome_back'.tr(), style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(
            'dashboard_subtitle'.tr(),
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 24.0),
          // Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  _buildMetricCard(
                    title: 'total_users'.tr(),
                    value: summary.totalUsers.toString(),
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    route: AppRoutes.users,
                  ),
                  _buildMetricCard(
                    title: 'total_brokers'.tr(),
                    value: summary.totalBrokers.toString(),
                    icon: Icons.business_rounded,
                    color: AppColors.secondary,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    route: AppRoutes.brokers,
                  ),
                  _buildMetricCard(
                    title: 'total_properties'.tr(),
                    value: summary.totalProperties.toString(),
                    icon: Icons.apartment_rounded,
                    color: AppColors.info,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    route: AppRoutes.properties,
                  ),
                  _buildMetricCard(
                    title: 'total_leads'.tr(),
                    value: summary.totalLeads.toString(),
                    icon: Icons.contact_phone_rounded,
                    color: AppColors.warning,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    route: AppRoutes.socialLeads,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32.0),
          // System Health & Activity Overview Container
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.health_and_safety_rounded, color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'system_health'.tr(),
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        '100% Operational',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'All core microservices including Supabase DB, Authentication, Storage, and Real-Time Event Listener Bus are functioning normally.',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
    String? route,
  }) {
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: route != null ? () => context.go(route) : null,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: color, size: 24.0),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      value,
                      style: AppTextStyles.heading1.copyWith(fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
