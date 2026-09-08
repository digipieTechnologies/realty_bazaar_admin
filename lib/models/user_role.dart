/// User role definitions and permission helpers.
library;

/// Enum representing user roles in the system.
enum UserRole { superAdmin, broker, marketing, user, unknown }

/// Extension to parse role string from API to UserRole enum.
extension UserRoleParser on String? {
  /// Converts API role string to UserRole enum.
  /// Handles null and unknown values gracefully.
  UserRole get asUserRole {
    switch (this?.toLowerCase().trim()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'broker':
        return UserRole.broker;
      case 'marketing':
        return UserRole.marketing;
      case 'user':
        return UserRole.user;
      default:
        return UserRole.unknown;
    }
  }
}

/// Extension providing permission checks for each role.
extension UserRolePermissions on UserRole {
  /// Whether user has super admin privileges.
  bool get isSuperAdmin => this == UserRole.superAdmin;

  /// Whether user is a broker.
  bool get isBroker => this == UserRole.broker;

  /// Whether user is in marketing team.
  bool get isMarketing => this == UserRole.marketing;

  /// Whether user is a standard user.
  bool get isUser => this == UserRole.user;

  /// Whether user can manage system users.
  bool get canManageUsers => this == UserRole.superAdmin;

  /// Display name for the role (for UI).
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.broker:
        return 'Broker';
      case UserRole.marketing:
        return 'Marketing';
      case UserRole.user:
        return 'User';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  /// API value for the user role (snake_case for backend).
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.broker:
        return 'broker';
      case UserRole.marketing:
        return 'marketing';
      case UserRole.user:
        return 'user';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  /// API value for filtering lists (null for unknown).
  String? get apiValueForList {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.broker:
        return 'broker';
      case UserRole.marketing:
        return 'marketing';
      case UserRole.user:
        return 'user';
      default:
        return null;
    }
  }
}
