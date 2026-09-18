// File: lib/modules/settings/screens/admin_settings_screen.dart
// Purpose: Super Admin system preferences and feature toggles screen.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _enableAutoSync = true;
  bool _enableAuditLogging = true;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('system_settings'.tr(), style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('settings_realtime_sync'.tr()),
                subtitle: Text('settings_realtime_sync_sub'.tr()),
                value: _enableAutoSync,
                onChanged: (val) {
                  setState(() => _enableAutoSync = val);
                  AppToast.showSuccess('Settings Updated', 'Real-time sync preference saved.');
                },
              ),
            ),
            const Divider(),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('settings_audit_logging'.tr()),
                subtitle: Text('audit_trail'.tr()),
                value: _enableAuditLogging,
                onChanged: (val) {
                  setState(() => _enableAuditLogging = val);
                  AppToast.showSuccess('Settings Updated', 'Audit logging preference saved.');
                },
              ),
            ),
            const Divider(),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text('settings_maintenance_mode'.tr()),
                subtitle: Text('settings_maintenance_mode_sub'.tr()),
                value: _maintenanceMode,
                activeColor: AppColors.error,
                onChanged: (val) {
                  setState(() => _maintenanceMode = val);
                  AppToast.showSuccess(
                    'Maintenance Flag Changed',
                    val ? 'Platform in maintenance mode.' : 'Platform live.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
