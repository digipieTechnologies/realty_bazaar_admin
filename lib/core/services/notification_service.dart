// File: lib/core/services/notification_service.dart
// Purpose: Cross-platform Push Notification service for OneSignal with tap routing for Admin app.

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../app/app_constants.dart';
import '../../app/app_routes.dart';
import '../../main.dart';
import '../../models/notification_enums.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _isInitialized = false;

  /// Initializes OneSignal SDK using ONE_SIGNAL_APP_ID passed via --dart-define-from-file=..env.dev or ..env.prod.
  Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('OneSignal is only enabled for Android and iOS. Skipping initialization on desktop/web.');
      return;
    }

    if (_isInitialized) return;

    try {
      const String oneSignalAppId = String.fromEnvironment('ONE_SIGNAL_APP_ID');

      if (oneSignalAppId.isNotEmpty) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(oneSignalAppId);

        // Prompt native system notification permission directly
        OneSignal.Notifications.requestPermission(true);

        OneSignal.Notifications.addClickListener((event) {
          final data = event.notification.additionalData;
          if (data != null) {
            _handleNotificationClick(Map<String, dynamic>.from(data));
          }
        });

        _isInitialized = true;
        debugPrint('OneSignal NotificationService initialized successfully with App ID: $oneSignalAppId');
      } else {
        debugPrint(
          'ONE_SIGNAL_APP_ID missing from String.fromEnvironment. Make sure to build/run with --dart-define-from-file=..env.dev or ..env.prod',
        );
      }
    } catch (e) {
      debugPrint('Error initializing OneSignal NotificationService: $e');
    }
  }

  /// Binds logged in admin user's Supabase UUID to OneSignal's external_id.
  Future<void> bindUserToOneSignal(String userId) async {
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }
      if (_isInitialized) {
        await OneSignal.login(userId);
        debugPrint('OneSignal user logged in with ID: $userId');
      }
    } catch (e) {
      debugPrint('Error logging user into OneSignal: $e');
    }
  }

  /// Unbinds user from OneSignal on logout.
  Future<void> unbindUserFromOneSignal() async {
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      if (_isInitialized) {
        await OneSignal.logout();
        debugPrint('OneSignal user logged out.');
      }
    } catch (e) {
      debugPrint('Error logging out from OneSignal: $e');
    }
  }

  /// Routes admin user according to NotificationType payload data.
  void _handleNotificationClick(Map<String, dynamic> data) {
    try {
      debugPrint('🔔 [NotificationService] Click payload data: $data');

      final rawType = data['notification_type']?.toString() ?? data['type']?.toString();
      final notificationType = NotificationType.fromDbValue(rawType);

      debugPrint('🔔 [NotificationService] Parsed notification type: $notificationType');

      String targetPath = AppRoutes.dashboard;

      switch (notificationType) {
        case NotificationType.lead:
          final leadId = data['lead_id']?.toString() ?? data['leadId']?.toString() ?? data['id']?.toString();
          if (leadId != null && leadId.isNotEmpty && leadId != 'null') {
            targetPath = AppRoutes.socialLeadDetailPath(leadId);
          } else {
            targetPath = AppRoutes.socialLeads;
          }
          break;

        case NotificationType.videoRequest:
          final requestId = data['video_request_id']?.toString() ?? data['id']?.toString();
          if (requestId != null && requestId.isNotEmpty && requestId != 'null') {
            targetPath = AppRoutes.videoRequestDetailPathHelper(requestId);
          } else {
            targetPath = AppRoutes.videoRequests;
          }
          break;
        case NotificationType.launchProperty:
          final propertyId = data['property_id']?.toString() ?? data['id']?.toString();
          if (propertyId != null && propertyId.isNotEmpty && propertyId != 'null') {
            targetPath = AppRoutes.propertyDetailPathHelper(propertyId);
          } else {
            targetPath = AppRoutes.properties;
          }
          break;
      }

      debugPrint('👉 [NotificationService] Target notification path: $targetPath');

      final currentRoute = AppRoutes.router.routerDelegate.currentConfiguration.uri.toString();
      final isAppOpen = currentRoute.isNotEmpty && currentRoute != '/' && currentRoute != AppRoutes.login;

      if (isAppOpen) {
        // App is already open and running: navigate directly
        debugPrint('👉 [NotificationService] App is open ($currentRoute). Pushing $targetPath');
        AppRoutes.router.push(targetPath);
      } else {
        // App is not open (cold launch): store pendingRedirectKey for AppBootstrap to consume
        debugPrint('👉 [NotificationService] App is not open ($currentRoute). Storing pendingRedirectKey: $targetPath');
        _storePendingRedirect(targetPath);
      }
    } catch (e, stack) {
      debugPrint('❌ Error routing notification click: $e\n$stack');
    }
  }

  /// Stores the pending redirect path using SharedPreferences (async-safe fallback)
  Future<void> _storePendingRedirect(String path) async {
    try {
      await sharedPrefs.setString(AppConstants.pendingRedirectKey, path);
    } catch (e) {
      debugPrint('Error storing pending redirect: $e');
    }
  }
}
