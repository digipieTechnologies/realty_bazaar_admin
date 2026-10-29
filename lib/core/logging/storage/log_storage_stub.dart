// File: lib/core/logging/storage/log_storage_stub.dart
// Purpose: Fallback stub implementation of LogStorage for unsupported platforms.

import 'package:flutter/widgets.dart';

import 'log_storage.dart';

class LogStorageImplementation implements LogStorage {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> appendLog(String formattedEntry) async {}

  @override
  Future<String> readLogs() async => '';

  @override
  Future<void> clearLogs() async {}

  @override
  Future<String?> exportLogs({String? suggestedFileName}) async => null;

  @override
  Future<bool> shareLogs({String? subject, BuildContext? context}) async => false;

  @override
  Future<int> getLogSizeBytes() async => 0;

  @override
  Future<int> getLogCount() async => 0;
}

LogStorage createPlatformLogStorage() => LogStorageImplementation();
