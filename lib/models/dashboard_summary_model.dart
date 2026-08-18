// File: lib/models/dashboard_summary_model.dart
// Purpose: Data model representing Super Admin dashboard summary metrics returned from Supabase RPC function.

class DashboardSummaryModel {
  final int totalUsers;
  final int totalBrokers;
  final int totalProperties;
  final int totalLeads;

  const DashboardSummaryModel({
    this.totalUsers = 0,
    this.totalBrokers = 0,
    this.totalProperties = 0,
    this.totalLeads = 0,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalBrokers: (json['total_brokers'] as num?)?.toInt() ?? 0,
      totalProperties: (json['total_properties'] as num?)?.toInt() ?? 0,
      totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_brokers': totalBrokers,
      'total_properties': totalProperties,
      'total_leads': totalLeads,
    };
  }
}
