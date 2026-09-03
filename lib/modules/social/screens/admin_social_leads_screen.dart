// File: lib/modules/social/screens/admin_social_leads_screen.dart
// Purpose: Super Admin Social Leads intelligence table using AppDataTable.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/social/admin_social_provider.dart';
import '../../../widgets/common/app_data_table.dart';

class AdminSocialLeadsScreen extends StatefulWidget {
  const AdminSocialLeadsScreen({super.key});

  @override
  State<AdminSocialLeadsScreen> createState() => _AdminSocialLeadsScreenState();
}

class _AdminSocialLeadsScreenState extends State<AdminSocialLeadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSocialProvider>().fetchSocialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminSocialProvider>();
    final list = prov.leads;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('social_leads'.tr(), style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${list.length} Captured Leads',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppDataTable(
            isLoading: prov.isLoading,
            columns: [
              AppDataColumn(label: 'lead_name'.tr(), flex: 2),
              AppDataColumn(label: 'email'.tr(), flex: 2),
              AppDataColumn(label: 'phone'.tr(), flex: 1.5),
              AppDataColumn(label: 'platform'.tr(), flex: 1.2),
              AppDataColumn(label: 'status'.tr(), flex: 1),
            ],
            rows: list.map((lead) => _buildRow(lead)).toList(),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(SocialLeadModel lead) {
    return DataRowItem(
      cells: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondaryLight,
              child: const Icon(Icons.person_rounded, color: AppColors.secondary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lead.leadName.isNotEmpty ? lead.leadName : '-',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        DataCellText(text: lead.leadEmail ?? '-'),
        DataCellText(text: lead.leadPhone.isNotEmpty ? lead.leadPhone : '-'),
        DataCellText(text: lead.platform ?? '-'),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
            child: Text(
              lead.status.label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.info),
            ),
          ),
        ),
      ],
    );
  }
}
