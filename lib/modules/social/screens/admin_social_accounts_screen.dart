// File: lib/modules/social/screens/admin_social_accounts_screen.dart
// Purpose: Super Admin Connected Social Accounts overview using AppDataTable.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/social/admin_social_provider.dart';
import '../../../widgets/common/app_data_table.dart';

class AdminSocialAccountsScreen extends StatefulWidget {
  const AdminSocialAccountsScreen({super.key});

  @override
  State<AdminSocialAccountsScreen> createState() => _AdminSocialAccountsScreenState();
}

class _AdminSocialAccountsScreenState extends State<AdminSocialAccountsScreen> {
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
    final list = prov.accounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'social_accounts'.tr(),
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${list.length} Connected Accounts',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppDataTable(
            isLoading: prov.isLoading,
            columns: [
              AppDataColumn(label: 'account_name'.tr(), flex: 2),
              AppDataColumn(label: 'platform'.tr(), flex: 1.5),
              AppDataColumn(label: 'followers'.tr(), flex: 1.5, numeric: true),
              AppDataColumn(label: 'status'.tr(), flex: 1),
            ],
            rows: list.map((acc) => _buildRow(acc)).toList(),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(SocialAccountModel acc) {
    return DataRowItem(
      cells: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(_getPlatformIcon(acc.platform), color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                acc.accountName ?? '-',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        DataCellText(text: acc.platform ?? '-'),
        DataCellText(text: '${acc.followersCount ?? 0}', numeric: true),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'CONNECTED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'linkedin':
        return Icons.work_rounded;
      default:
        return Icons.share_rounded;
    }
  }
}
