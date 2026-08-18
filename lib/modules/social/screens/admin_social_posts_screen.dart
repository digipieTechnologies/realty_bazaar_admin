// File: lib/modules/social/screens/admin_social_posts_screen.dart
// Purpose: Super Admin Published and Scheduled Social Posts catalog using AppDataTable.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/social/admin_social_provider.dart';
import '../../../widgets/common/app_data_table.dart';

class AdminSocialPostsScreen extends StatefulWidget {
  const AdminSocialPostsScreen({super.key});

  @override
  State<AdminSocialPostsScreen> createState() => _AdminSocialPostsScreenState();
}

class _AdminSocialPostsScreenState extends State<AdminSocialPostsScreen> {
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
    final list = prov.posts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('social_posts'.tr(), style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${list.length} Posts',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppDataTable(
            isLoading: prov.isLoading,
            columns: [
              AppDataColumn(label: 'post_caption'.tr(), flex: 3),
              AppDataColumn(label: 'platform'.tr(), flex: 1.5),
              AppDataColumn(label: 'status'.tr(), flex: 1),
            ],
            rows: list.map((post) => _buildRow(post)).toList(),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(SocialPostModel post) {
    return DataRowItem(
      cells: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.article_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                post.caption ?? '-',
                style: AppTextStyles.body1,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        DataCellText(text: post.platform ?? '-'),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
            child: Text(
              (post.status ?? 'published').toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
          ),
        ),
      ],
    );
  }
}
