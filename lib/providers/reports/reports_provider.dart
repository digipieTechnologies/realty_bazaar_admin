// File: lib/providers/reports/reports_provider.dart
// Purpose: System performance analytics & metrics provider with real API metrics calculation.

import 'package:flutter/material.dart';

import '../../core/services/admin_data_service.dart';

class ReportsProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Map<String, dynamic> _metrics = {
    'monthlyGrowth': '+18.4%',
    'activeSubscribers': '0',
    'totalUsersCount': '0',
    'totalLeadsGenerated': '0',
    'systemUptime': '99.98%',
    'platformDistribution': {'Instagram': 45, 'Facebook': 35, 'LinkedIn': 20},
  };

  Map<String, dynamic> get metrics => _metrics;

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    _metrics = await AdminDataService.instance.getSystemMetrics();

    _isLoading = false;
    notifyListeners();
  }
}
