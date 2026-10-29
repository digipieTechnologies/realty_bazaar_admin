// File: lib/core/logging/app_log_service.dart
// Purpose: Centralized diagnostic error, crash, and warning logging service with privacy redaction and context enrichment.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../main.dart';
import 'storage/log_storage_provider.dart';

class AppLogService {
  AppLogService._();

  static final AppLogService instance = AppLogService._();

  late final LogStorage _storage;
  bool _initialized = false;

  // Cached device and app context
  String _appVersion = 'Unknown';
  String _buildNumber = '';
  String _platformName = 'Unknown';

  // Cached tenant and user context
  String? _userId;
  String? _userName;
  String? _orgId;
  String? _orgName;

  LogStorage get storage => _storage;

  /// Returns cached app version (e.g. '1.0.0').
  String get appVersion => _appVersion;

  /// Returns cached build number (e.g. '5').
  String get buildNumber => _buildNumber;

  /// Returns formatted full version, e.g. '1.0.0+5'.
  String get fullVersion {
    final version = (_appVersion != 'Unknown' && _appVersion.isNotEmpty) ? _appVersion : '1.0.0';
    if (_buildNumber.isNotEmpty) {
      return '$version+$_buildNumber';
    }
    return version;
  }

  /// Resolves or returns the full version string asynchronously.
  Future<String> getResolvedFullVersion() async {
    if (_buildNumber.isNotEmpty && _appVersion != 'Unknown') {
      return fullVersion;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (e) {
      debugPrint('Error retrieving package info: $e');
      if (_appVersion == 'Unknown') _appVersion = '1.0.0';
    }
    return fullVersion;
  }

  /// Initializes the storage engine, resolves app version, and prepares system metadata.
  Future<void> initialize() async {
    if (_initialized) return;

    _storage = createLogStorage();
    await _storage.initialize();

    // Resolve platform name
    if (kIsWeb) {
      _platformName = 'Web Browser';
    } else {
      _platformName = defaultTargetPlatform.name.toUpperCase();
    }

    // Resolve package info
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } catch (e) {
      debugPrint('Error retrieving package info: $e');
      _appVersion = '1.0.0';
    }

    _initialized = true;
  }

  /// Updates active user and organization / broker tenant context for subsequent logs.
  void updateUserContext({String? userId, String? userName, String? orgId, String? orgName}) {
    if (userId != null) _userId = userId;
    if (userName != null) _userName = userName;
    if (orgId != null) _orgId = orgId;
    if (orgName != null) _orgName = orgName;
  }

  /// Clears user and organization context (e.g. on sign out).
  void clearUserContext() {
    _userId = null;
    _userName = null;
    _orgId = null;
    _orgName = null;
  }

  /// Logs a fatal or framework-level application crash.
  Future<void> logCrash(dynamic error, StackTrace? stack, {String? tag = 'CRASH', Map<String, dynamic>? extra}) async {
    await _writeEntry(
      level: 'FATAL',
      tag: tag ?? 'CRASH',
      message: error?.toString() ?? 'Unknown fatal error',
      error: error,
      stackTrace: stack,
      extra: extra,
    );
  }

  /// Logs an unexpected error or caught exception.
  Future<void> logError(dynamic error, {StackTrace? stack, String? tag = 'ERROR', Map<String, dynamic>? extra}) async {
    await _writeEntry(
      level: 'ERROR',
      tag: tag ?? 'ERROR',
      message: error?.toString() ?? 'Unknown error',
      error: error,
      stackTrace: stack,
      extra: extra,
    );
  }

  /// Logs a recoverable warning or high-priority diagnostic notice.
  Future<void> logWarning(String message, {String? tag = 'WARN', Map<String, dynamic>? extra}) async {
    await _writeEntry(level: 'WARN', tag: tag ?? 'WARN', message: message, extra: extra);
  }

  /// Logs general informational diagnostics.
  Future<void> logInfo(String message, {String? tag = 'INFO', Map<String, dynamic>? extra}) async {
    await _writeEntry(level: 'INFO', tag: tag ?? 'INFO', message: message, extra: extra);
  }

  /// Writes and persists a formatted, redacted log entry.
  Future<void> _writeEntry({
    required String level,
    required String tag,
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final nowUtc = DateTime.now().toUtc();
      // Indian Standard Time is UTC + 5 hours 30 minutes
      final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));
      final istFormatted = DateFormat('dd-MMM-yyyy hh:mm:ss a').format(nowIst);
      final utcFormatted = nowUtc.toIso8601String();

      // Retrieve dynamic session user/org if not set in memory
      String resolvedUserId = _userId ?? '';
      String resolvedUserName = _userName ?? '';
      String resolvedOrgId = _orgId ?? '';
      String resolvedOrgName = _orgName ?? '';

      if (resolvedUserId.isEmpty) {
        try {
          final storedUserId = sharedPrefs.getString('user_id');
          if (storedUserId != null && storedUserId.isNotEmpty) {
            resolvedUserId = storedUserId;
          }
        } catch (_) {}
      }

      final buffer = StringBuffer();
      // Timestamp & Level line: [IST: <time> | UTC: <timestamp>] [LEVEL] [TAG]
      buffer.writeln('[IST: $istFormatted | UTC: $utcFormatted] [$level] [$tag]');

      // Context line
      buffer.write('Platform: $_platformName | App: v$_appVersion');
      if (_buildNumber.isNotEmpty) buffer.write('+$_buildNumber');
      if (resolvedOrgId.isNotEmpty || resolvedOrgName.isNotEmpty) {
        buffer.write(' | Org: ${resolvedOrgName.isNotEmpty ? resolvedOrgName : "Unknown"} ($resolvedOrgId)');
      }
      if (resolvedUserId.isNotEmpty || resolvedUserName.isNotEmpty) {
        buffer.write(' | User: ${resolvedUserName.isNotEmpty ? resolvedUserName : "Unknown"} ($resolvedUserId)');
      }
      buffer.writeln();

      // Message line
      buffer.writeln('Message: ${_sanitize(message)}');

      // Extra metadata if present
      if (extra != null && extra.isNotEmpty) {
        buffer.writeln('Details: ${_sanitize(extra.toString())}');
      }

      // Stack trace line
      if (stackTrace != null) {
        buffer.writeln('StackTrace:');
        buffer.writeln(_cleanStackTrace(stackTrace.toString()));
      }

      final formattedEntry = buffer.toString().trim();

      // Console debug output during local development
      if (kDebugMode) {
        debugPrint('📋 [AppLogService] [$level] [$tag]: $message');
      }

      await _storage.appendLog(formattedEntry);
    } catch (e) {
      debugPrint('AppLogService failed to write entry: $e');
    }
  }

  /// Redacts sensitive information such as Bearer tokens, passwords, API keys, and secrets.
  String _sanitize(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;

    // 1. Redact Authorization Bearer tokens: Bearer <token>
    sanitized = sanitized.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      'Bearer [REDACTED]',
    );

    // 2. Redact JSON password values: "password": "...", "pwd": "..."
    sanitized = sanitized.replaceAll(
      RegExp(r'["\x27]?(?:password|passwd|pwd)["\x27]?\s*[:=]\s*["\x27]?[^,"\x27\s}]+["\x27]?', caseSensitive: false),
      'password: "[REDACTED]"',
    );

    // 3. Redact API keys and secret tokens
    sanitized = sanitized.replaceAll(
      RegExp(
        r'["\x27]?(?:secret|apiKey|api_key|service_role|access_token|refresh_token)["\x27]?\s*[:=]\s*["\x27]?[^,"\x27\s}]+["\x27]?',
        caseSensitive: false,
      ),
      'secret: "[REDACTED]"',
    );

    // 4. Redact URL query parameter tokens: ?token=... or &password=...
    sanitized = sanitized.replaceAll(
      RegExp(r'([?&](?:token|password|secret|key)=)[^&]+', caseSensitive: false),
      r'$1[REDACTED]',
    );

    return sanitized;
  }

  /// Cleans and formats stack trace by trimming excessive framework lines.
  String _cleanStackTrace(String stack) {
    final lines = stack.split('\n');
    final sanitizedLines = lines.take(25).map((l) => '  $l').join('\n');
    return sanitizedLines;
  }

  /// Exports the log file and returns the downloaded filename or saved path.
  Future<String?> exportLogs({BuildContext? context}) async {
    if (!_initialized) await initialize();
    return await _storage.exportLogs();
  }

  /// Opens the native share sheet or copies logs to clipboard.
  Future<bool> shareLogs({BuildContext? context}) async {
    if (!_initialized) await initialize();
    if (context != null && !context.mounted) return false;
    return await _storage.shareLogs(subject: 'The Realty Bazaar Diagnostic Error Logs', context: context);
  }

  /// Clears stored log entries.
  Future<void> clearLogs() async {
    if (!_initialized) await initialize();
    await _storage.clearLogs();
  }

  /// Returns storage size occupied by logs in bytes.
  Future<int> getLogSizeBytes() async {
    if (!_initialized) await initialize();
    return await _storage.getLogSizeBytes();
  }

  /// Returns total number of log entries recorded.
  Future<int> getLogCount() async {
    if (!_initialized) await initialize();
    return await _storage.getLogCount();
  }

  /// Reads stored logs as string.
  Future<String> readLogs() async {
    if (!_initialized) await initialize();
    return await _storage.readLogs();
  }
}
