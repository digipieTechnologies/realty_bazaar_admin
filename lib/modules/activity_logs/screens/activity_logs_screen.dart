// File: lib/modules/activity_logs/screens/activity_logs_screen.dart
// Purpose: Super Admin activity logs audit trail screen using AppDataTable.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/activity_logs/activity_logs_provider.dart';
import '../../../widgets/common/app_data_table.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogsProvider>().fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ActivityLogsProvider>();
    final list = prov.logs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('audit_trail'.tr(), style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '${list.length} Log Entries',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppDataTable(
            isLoading: prov.isLoading,
            columns: [
              AppDataColumn(label: 'action_actor'.tr(), flex: 2),
              AppDataColumn(label: 'target_entity'.tr(), flex: 1.5),
              AppDataColumn(label: 'details'.tr(), flex: 2.5),
              AppDataColumn(label: 'time'.tr(), flex: 1, numeric: true),
            ],
            rows: list.map((log) => _buildRow(log)).toList(),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(ActivityLogModel log) {
    final timeStr = log.createdAt != null
        ? '${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}'
        : '-';

    return DataRowItem(
      cells: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${log.action ?? '-'} • ${log.actorName ?? 'System'}',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        DataCellText(text: log.targetEntity ?? '-'),
        DataCellText(text: log.details ?? '-'),
        DataCellText(text: timeStr, numeric: true),
      ],
    );
  }
}
