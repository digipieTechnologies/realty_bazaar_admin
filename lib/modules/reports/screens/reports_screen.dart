// File: lib/modules/reports/screens/reports_screen.dart
// Purpose: Super Admin analytics and performance reports screen.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/reports/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReportsProvider>();
    final metrics = prov.metrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'performance_reports'.tr(),
            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _buildReportCard(
                  'Monthly Platform Growth',
                  metrics['monthlyGrowth'],
                  AppColors.success,
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildReportCard(
                  'Active Paid Subscribers',
                  metrics['activeSubscribers'],
                  AppColors.primary,
                  Icons.card_membership_rounded,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: _buildReportCard(
                  'System Uptime Sla',
                  metrics['systemUptime'],
                  AppColors.info,
                  Icons.speed_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.heading1.copyWith(color: color)),
        ],
      ),
    );
  }
}
