// File: lib/core/logging/storage/log_storage.dart
// Purpose: Abstract cross-platform interface for persistent error log storage, querying, size monitoring, and sharing.

import 'package:flutter/widgets.dart';

abstract class LogStorage {
  /// Maximum allowed storage size for rolling logs (~2 MB).
  static const int maxLogSizeBytes = 2 * 1024 * 1024; // 2 MB

  /// Target soft maximum entry count (~1000 entries).
  static const int maxLogEntries = 1000;

  /// Default file name for error log exports.
  static const String defaultLogFileName = 'app_errors.log';

  /// Initializes the storage mechanism (creates directories, opens IndexedDB, etc.).
  Future<void> initialize();

  /// Prepends a new log entry to the top of the storage (reverse chronological order).
  Future<void> appendLog(String formattedEntry);

  /// Reads all stored logs as a continuous string (newest first).
  Future<String> readLogs();

  /// Clears all stored log entries.
  Future<void> clearLogs();

  /// Exports the log file.
  /// On Desktop/Mobile: Saves or prompts to save the file.
  /// On Web: Generates a Blob URL and triggers automatic browser download.
  /// Returns the saved path or download confirmation identifier if successful.
  Future<String?> exportLogs({String? suggestedFileName});

  /// Shares the logs.
  /// On Mobile/Desktop: Invokes the native system share sheet.
  /// On Web: Copies logs to the clipboard with visual confirmation.
  Future<bool> shareLogs({String? subject, BuildContext? context});

  /// Returns current storage size occupied by the logs in bytes.
  Future<int> getLogSizeBytes();

  /// Returns the approximate count of log entries stored.
  Future<int> getLogCount();
}
