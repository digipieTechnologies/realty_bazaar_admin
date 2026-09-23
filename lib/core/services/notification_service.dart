// File: lib/core/services/notification_service.dart
// Purpose: Cross-platform Firebase Cloud Messaging (FCM) Notification Service for Admin app with foreground, background, and cold-launch handling.

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/app_constants.dart';
import '../../app/app_routes.dart';
import '../../main.dart';
import '../../models/notification_enums.dart';
import '../../widgets/toast/app_toast.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM Admin Background Handler] Message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _isInitialized = false;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  /// Initializes FCM listeners and notification click handlers across Android, iOS, macOS, and Web.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ [NotificationService] Firebase not initialized yet.');
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsIOS,
      );

      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              debugPrint('🔔 [Local Notification Tapped] payload: $data');
              _handleNotificationClick(data);
            } catch (e) {
              debugPrint('Error parsing local notification payload: $e');
            }
          }
        },
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? 'New Notification';
        final body = notification?.body ?? '';

        if (notification != null) {
          final ctx = AppRoutes.rootNavigatorKey.currentContext;
          if (ctx != null) {
            AppToast.showNotification(
              title,
              body,
              onTap: () {
                _handleNotificationClick(message.data);
              },
            );
          }
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM App Opened] Notification tapped with payload data: ${message.data}');
        _handleNotificationClick(message.data);
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 [FCM Initial Message] App opened from terminated state via payload data: ${initialMessage.data}');
        _handleNotificationClick(initialMessage.data);
      }

      _isInitialized = true;
      debugPrint('✅ FCM Admin NotificationService initialized successfully!');
    } catch (e, stack) {
      debugPrint('❌ Error initializing FCM Admin NotificationService: $e\n$stack');
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
        debugPrint('👉 [NotificationService] App is open ($currentRoute). Pushing $targetPath');
        AppRoutes.router.push(targetPath);
      } else {
        debugPrint('👉 [NotificationService] App is not open ($currentRoute). Storing pendingRedirectKey: $targetPath');
        _storePendingRedirect(targetPath);
      }
    } catch (e, stack) {
      debugPrint('❌ Error routing notification click: $e\n$stack');
    }
  }

  Future<void> _storePendingRedirect(String path) async {
    try {
      await sharedPrefs.setString(AppConstants.pendingRedirectKey, path);
    } catch (e) {
      debugPrint('Error storing pending redirect: $e');
    }
  }
}
