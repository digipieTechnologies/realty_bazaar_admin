// File: lib/core/services/device_service.dart
// Purpose: Multi-platform device metadata collector and FCM token syncer with atomic Supabase RPC registration for Admin app.

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../network/supabase_client.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const String _webDeviceIdKey = 'user_device_web_id';
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isListeningToRefresh = false;

  /// Retrieves a persistent, unique device identifier across all platforms.
  Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        String? webId = prefs.getString(_webDeviceIdKey);
        if (webId == null || webId.isEmpty) {
          webId = 'web_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9000 * (DateTime.now().microsecond / 1000000))).toInt()}';
          await prefs.setString(_webDeviceIdKey, webId);
        }
        return webId;
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id.isNotEmpty ? androidInfo.id : 'android_${androidInfo.model}';
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_${iosInfo.name}';
      }

      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.systemGUID ?? 'macos_${macInfo.computerName}';
      }

      if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        return winInfo.deviceId.isNotEmpty ? winInfo.deviceId : 'win_${winInfo.computerName}';
      }

      if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? 'linux_${linuxInfo.name}';
      }
    } catch (e) {
      debugPrint('Error getting deviceId: $e');
    }

    return 'device_unknown';
  }

  /// Retrieves human-readable device name.
  Future<String> getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        final browser = webInfo.browserName.name;
        final platform = webInfo.platform ?? 'Web';
        return '$browser on $platform';
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand.isNotEmpty ? androidInfo.brand : androidInfo.manufacturer;
        return '${_capitalize(brand)} ${androidInfo.model}';
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name.isNotEmpty ? iosInfo.name : 'iPhone (${iosInfo.model})';
      }

      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return '${macInfo.computerName} (Mac)';
      }

      if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        return '${winInfo.computerName} (Windows)';
      }
    } catch (e) {
      debugPrint('Error getting deviceName: $e');
    }

    return 'Unknown Device';
  }

  /// Returns standard platform enum string matching PostgreSQL device_platform_enum.
  String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'android';
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  /// Safely fetches the FCM token for the device.
  Future<String?> getFcmToken() async {
    try {
      await _ensureFirebaseInitialized();
      if (Firebase.apps.isEmpty) return null;

      final messaging = FirebaseMessaging.instance;

      // On Android / iOS mobile, request native runtime OS notification permissions
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            final newStatus = await Permission.notification.request();
            debugPrint('📱 [DeviceService] Notification permission request result: $newStatus');
          }
        } catch (e) {
          debugPrint('Notification permission request note: $e');
        }
      }

      // Request permission via FirebaseMessaging SDK
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      String? token;
      if (kIsWeb) {
        const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
        if (vapidKey.isEmpty) {
          debugPrint('⚠️ [DeviceService] Missing FCM_VAPID_KEY for Web Push!');
        }
        token = await messaging.getToken(vapidKey: vapidKey.isNotEmpty ? vapidKey : null);
      } else {
        // On Android / Mobile, fetch FCM device token directly from Firebase Messaging SDK
        token = await messaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 [DeviceService] FCM Token retrieved successfully: $token');
        return token;
      }
    } catch (e) {
      debugPrint('❌ [DeviceService] Error getting FCM token: $e');
    }
    return null;
  }

  /// Gets App Version and Build Number.
  Future<(String, int)> getAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final buildNum = int.tryParse(info.buildNumber) ?? 1;
      return (info.version, buildNum);
    } catch (e) {
      return ('1.0.0', 1);
    }
  }

  /// Gets OS version string.
  Future<String> getOsVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? 'Web Browser';
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }

      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'macOS ${macInfo.majorVersion}.${macInfo.minorVersion}.${macInfo.patchVersion}';
      }

      if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        return 'Windows ${winInfo.majorVersion}.${winInfo.minorVersion} (Build ${winInfo.buildNumber})';
      }
    } catch (e) {
      debugPrint('Error getting OS version: $e');
    }
    return 'Unknown OS';
  }

  /// Synchronizes device metadata and FCM token with Supabase via rpc_upsert_user_device.
  Future<bool> syncCurrentDevice(String userId) async {
    if (userId.isEmpty) return false;

    try {
      debugPrint('📱 [DeviceService] Starting device & FCM token sync for admin user $userId...');

      final deviceId = await getDeviceId();
      final deviceName = await getDeviceName();
      final platformStr = getPlatform();
      final fcmToken = await getFcmToken();
      final (appVersion, buildNum) = await getAppInfo();
      final osVersion = await getOsVersion();

      debugPrint('📱 [DeviceService] Syncing device params: ID=$deviceId, Name=$deviceName, Platform=$platformStr, FCM Token=$fcmToken');

      await SupabaseConfig.client.rpc(
        'rpc_upsert_user_device',
        params: {
          'p_user_id': userId,
          'p_device_id': deviceId,
          'p_device_name': deviceName,
          'p_platform': platformStr,
          'p_fcm_token': fcmToken,
          'p_app_version': appVersion,
          'p_build_number': buildNum,
          'p_os_version': osVersion,
        },
      );

      debugPrint('✅ [DeviceService] rpc_upsert_user_device completed successfully for user $userId!');

      _setupTokenRefreshListener(userId);
      return true;
    } catch (e, stack) {
      debugPrint('❌ [DeviceService] Error syncing user device: $e\n$stack');
      return false;
    }
  }

  void _setupTokenRefreshListener(String userId) async {
    if (_isListeningToRefresh) return;
    try {
      await _ensureFirebaseInitialized();
      if (Firebase.apps.isEmpty) return;

      _isListeningToRefresh = true;
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 [DeviceService] FCM Token refreshed: $newToken. Re-syncing...');
        try {
          final deviceId = await getDeviceId();
          final deviceName = await getDeviceName();
          final platformStr = getPlatform();

          await SupabaseConfig.client.rpc(
            'rpc_upsert_user_device',
            params: {
              'p_user_id': userId,
              'p_device_id': deviceId,
              'p_device_name': deviceName,
              'p_platform': platformStr,
              'p_fcm_token': newToken,
            },
          );
        } catch (e) {
          debugPrint('Error updating refreshed FCM token: $e');
        }
      });
    } catch (e) {
      debugPrint('Error setting up FCM token refresh listener: $e');
    }
  }

  /// Deactivates current device in user_devices table, clears FCM token on server, and deletes device token on logout.
  Future<void> deactivateCurrentDevice() async {
    try {
      final deviceId = await getDeviceId();
      await SupabaseConfig.client
          .from('user_devices')
          .update({
            'is_active': false,
            'fcm_token': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('device_id', deviceId);

      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.deleteToken();
      }
      debugPrint('📱 [DeviceService] Device $deviceId deactivated and FCM token cleared on logout.');
    } catch (e) {
      debugPrint('Error deactivating device on logout: $e');
    } finally {
      dispose();
    }
  }

  /// Cancels refresh listeners on logout.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _isListeningToRefresh = false;
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
