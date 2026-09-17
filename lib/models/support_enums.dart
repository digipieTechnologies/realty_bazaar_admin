// File: lib/models/support_enums.dart
// Purpose: Type-safe enums for support categories, ticket statuses, and priorities in brokerflow_admin.

import 'package:flutter/material.dart';

import '../app/app_colors.dart';

enum SupportCategory {
  general,
  platformDemo,
  enterprise,
  partnership,
  marketing,
  support;

  String get dbValue {
    switch (this) {
      case SupportCategory.general:
        return 'general';
      case SupportCategory.platformDemo:
        return 'platform_demo';
      case SupportCategory.enterprise:
        return 'enterprise';
      case SupportCategory.partnership:
        return 'partnership';
      case SupportCategory.marketing:
        return 'marketing';
      case SupportCategory.support:
        return 'support';
    }
  }

  String get labelKey {
    switch (this) {
      case SupportCategory.general:
        return 'category_general';
      case SupportCategory.platformDemo:
        return 'category_platform_demo';
      case SupportCategory.enterprise:
        return 'category_enterprise';
      case SupportCategory.partnership:
        return 'category_partnership';
      case SupportCategory.marketing:
        return 'category_marketing';
      case SupportCategory.support:
        return 'category_support';
    }
  }

  static SupportCategory fromDbValue(String? value) {
    if (value == null) return SupportCategory.general;
    switch (value.toLowerCase().trim()) {
      case 'general':
        return SupportCategory.general;
      case 'platform_demo':
        return SupportCategory.platformDemo;
      case 'enterprise':
        return SupportCategory.enterprise;
      case 'partnership':
        return SupportCategory.partnership;
      case 'marketing':
        return SupportCategory.marketing;
      case 'support':
        return SupportCategory.support;
      default:
        return SupportCategory.general;
    }
  }
}

enum SupportTicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  String get dbValue {
    switch (this) {
      case SupportTicketStatus.open:
        return 'open';
      case SupportTicketStatus.inProgress:
        return 'in_progress';
      case SupportTicketStatus.resolved:
        return 'resolved';
      case SupportTicketStatus.closed:
        return 'closed';
    }
  }

  String get labelKey {
    switch (this) {
      case SupportTicketStatus.open:
        return 'status_open';
      case SupportTicketStatus.inProgress:
        return 'status_in_progress';
      case SupportTicketStatus.resolved:
        return 'status_resolved';
      case SupportTicketStatus.closed:
        return 'status_closed';
    }
  }

  Color get color {
    switch (this) {
      case SupportTicketStatus.open:
        return AppColors.info;
      case SupportTicketStatus.inProgress:
        return AppColors.warning;
      case SupportTicketStatus.resolved:
        return AppColors.success;
      case SupportTicketStatus.closed:
        return AppColors.textSecondary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SupportTicketStatus.open:
        return AppColors.infoLight;
      case SupportTicketStatus.inProgress:
        return AppColors.warningLight;
      case SupportTicketStatus.resolved:
        return AppColors.successLight;
      case SupportTicketStatus.closed:
        return AppColors.surfaceLight;
    }
  }

  static SupportTicketStatus fromDbValue(String? value) {
    if (value == null) return SupportTicketStatus.open;
    switch (value.toLowerCase().trim()) {
      case 'open':
        return SupportTicketStatus.open;
      case 'in_progress':
        return SupportTicketStatus.inProgress;
      case 'resolved':
        return SupportTicketStatus.resolved;
      case 'closed':
        return SupportTicketStatus.closed;
      default:
        return SupportTicketStatus.open;
    }
  }
}

enum SupportTicketPriority {
  low,
  normal,
  high,
  urgent;

  String get dbValue {
    switch (this) {
      case SupportTicketPriority.low:
        return 'low';
      case SupportTicketPriority.normal:
        return 'normal';
      case SupportTicketPriority.high:
        return 'high';
      case SupportTicketPriority.urgent:
        return 'urgent';
    }
  }

  String get labelKey {
    switch (this) {
      case SupportTicketPriority.low:
        return 'priority_low';
      case SupportTicketPriority.normal:
        return 'priority_normal';
      case SupportTicketPriority.high:
        return 'priority_high';
      case SupportTicketPriority.urgent:
        return 'priority_urgent';
    }
  }

  Color get color {
    switch (this) {
      case SupportTicketPriority.low:
        return AppColors.slate400;
      case SupportTicketPriority.normal:
        return AppColors.info;
      case SupportTicketPriority.high:
        return AppColors.warning;
      case SupportTicketPriority.urgent:
        return AppColors.error;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SupportTicketPriority.low:
        return AppColors.surfaceLight;
      case SupportTicketPriority.normal:
        return AppColors.infoLight;
      case SupportTicketPriority.high:
        return AppColors.warningLight;
      case SupportTicketPriority.urgent:
        return AppColors.errorLight;
    }
  }

  static SupportTicketPriority fromDbValue(String? value) {
    if (value == null) return SupportTicketPriority.normal;
    switch (value.toLowerCase().trim()) {
      case 'low':
        return SupportTicketPriority.low;
      case 'normal':
        return SupportTicketPriority.normal;
      case 'high':
        return SupportTicketPriority.high;
      case 'urgent':
        return SupportTicketPriority.urgent;
      default:
        return SupportTicketPriority.normal;
    }
  }
}
