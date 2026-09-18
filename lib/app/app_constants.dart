// File: lib/app/app_constants.dart
// Purpose: Core constants for Super Admin application.

class AppConstants {
  AppConstants._();

  static const String sessionKey = 'admin_user_id';

  /// Storage key for preserving notification deep link URL across cold launches.
  static const String pendingRedirectKey = 'pending_redirect_url';
}
