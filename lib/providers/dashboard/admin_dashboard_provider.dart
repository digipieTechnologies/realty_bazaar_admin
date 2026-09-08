// File: lib/providers/dashboard/admin_dashboard_provider.dart
// Purpose: Dedicated provider managing Super Admin dashboard summary metrics state fetched via Supabase RPC.

import 'package:flutter/foundation.dart';

import '../../core/services/admin_data_service.dart';
import '../../models/dashboard_summary_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final AdminDataService _dataService;

  AdminDashboardProvider({AdminDataService? dataService})
    : _dataService = dataService ?? AdminDataService.instance;

  DashboardSummaryModel _summary = const DashboardSummaryModel();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummaryModel get summary => _summary;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _dataService.getDashboardSummarySuperAdmin();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching dashboard summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
