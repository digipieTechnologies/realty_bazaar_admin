// File: lib/providers/activity_logs/activity_logs_provider.dart
// Purpose: Administrative audit trail provider.

import 'package:flutter/material.dart';

import '../../core/services/admin_data_service.dart';
import '../../models/activity_log_model.dart';

class ActivityLogsProvider extends ChangeNotifier {
  List<ActivityLogModel> _logs = [];
  bool _isLoading = false;

  List<ActivityLogModel> get logs => _logs;

  bool get isLoading => _isLoading;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    _logs = await AdminDataService.instance.getActivityLogs();

    _isLoading = false;
    notifyListeners();
  }
}
