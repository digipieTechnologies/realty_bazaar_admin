// File: lib/core/logging/storage/log_storage_io.dart
// Purpose: Native IO implementation of LogStorage with prepending rolling storage, async write queue, and native export/share.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'log_storage.dart';

class LogStorageImplementation implements LogStorage {
  static const String _entrySeparator =
      '\n================================================================================\n';

  File? _logFile;
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> _writeQueue = Future.value();

  @override
  Future<void> initialize() async {
    if (_initCompleter.isCompleted) return;
    try {
      Directory dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory('${Directory.systemTemp.path}/realty_bazaar_logs');
        }
      }

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      _logFile = File('${dir.path}/${LogStorage.defaultLogFileName}');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      _initCompleter.complete();
    } catch (e) {
      debugPrint('LogStorageImplementation (IO) init error: $e');
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<File?> _ensureFile() async {
    if (!_initCompleter.isCompleted) {
      await initialize();
    }
    return _logFile;
  }

  @override
  Future<void> appendLog(String formattedEntry) {
    // Chain onto the write queue to strictly serialize file writes
    final nextWrite = _writeQueue.then((_) async {
      try {
        final file = await _ensureFile();
        if (file == null) return;

        final newBlock = '$formattedEntry$_entrySeparator';
        final newBlockBytes = utf8.encode(newBlock);

        if (!await file.exists()) {
          await file.writeAsBytes(newBlockBytes, flush: true);
          return;
        }

        final currentBytes = await file.readAsBytes();
        final combinedBytes = <int>[...newBlockBytes, ...currentBytes];

        // Size Capping & Retention (~2 MB cap)
        if (combinedBytes.length > LogStorage.maxLogSizeBytes) {
          final trimmedText = _trimToFit(combinedBytes, LogStorage.maxLogSizeBytes);
          await file.writeAsString(trimmedText, flush: true);
        } else {
          await file.writeAsBytes(combinedBytes, flush: true);
        }
      } catch (e) {
        debugPrint('Failed to append log entry to IO file: $e');
      }
    });

    _writeQueue = nextWrite;
    return nextWrite;
  }

  String _trimToFit(List<int> bytes, int maxBytes) {
    String text = utf8.decode(bytes, allowMalformed: true);
    final entries = text.split(_entrySeparator);

    // Keep prepended entries (index 0 onwards) and trim from bottom
    final retained = <String>[];
    int accumulatedBytes = 0;

    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      final entryWithSep = '$trimmed$_entrySeparator';
      final entrySize = utf8.encode(entryWithSep).length;

      if (accumulatedBytes + entrySize > maxBytes && retained.isNotEmpty) {
        break; // Stop retaining older entries
      }
      retained.add(trimmed);
      accumulatedBytes += entrySize;
    }

    return retained.isEmpty ? '' : '${retained.join(_entrySeparator)}$_entrySeparator';
  }

  @override
  Future<String> readLogs() async {
    try {
      final file = await _ensureFile();
      if (file == null || !await file.exists()) return '';
      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading logs: $e');
      return '';
    }
  }

  @override
  Future<void> clearLogs() async {
    final nextWrite = _writeQueue.then((_) async {
      try {
        final file = await _ensureFile();
        if (file != null && await file.exists()) {
          await file.writeAsString('', flush: true);
        }
      } catch (e) {
        debugPrint('Error clearing logs: $e');
      }
    });
    _writeQueue = nextWrite;
    return nextWrite;
  }

  @override
  Future<String?> exportLogs({String? suggestedFileName}) async {
    try {
      final file = await _ensureFile();
      if (file == null || !await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final fileName = suggestedFileName ?? 'realty_bazaar_errors_${DateTime.now().millisecondsSinceEpoch}.log';

      final isDesktopPlatform =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux);

      if (isDesktopPlatform) {
        // Use FilePicker.saveFile for desktop save dialog
        try {
          final savePath = await FilePicker.saveFile(
            dialogTitle: 'Export Diagnostic Error Logs',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['log', 'txt'],
            bytes: bytes,
          );

          if (savePath != null) {
            final target = File(savePath);
            await target.writeAsBytes(bytes, flush: true);
            return savePath;
          }
        } catch (pickerError) {
          debugPrint('FilePicker saveFile fallback on desktop: $pickerError');
        }

        // Fallback to system Downloads directory
        Directory? downloadsDir;
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (_) {}

        downloadsDir ??= await getApplicationDocumentsDirectory();
        final targetPath = '${downloadsDir.path}/$fileName';
        final target = File(targetPath);
        await target.writeAsBytes(bytes, flush: true);
        return targetPath;
      } else {
        // Mobile platform (Android / iOS): Save to device documents / downloads folder
        Directory? destDir;
        try {
          destDir = await getDownloadsDirectory();
        } catch (_) {}
        destDir ??= await getApplicationDocumentsDirectory();

        final targetPath = '${destDir.path}/$fileName';
        final target = File(targetPath);
        await target.writeAsBytes(bytes, flush: true);
        return targetPath;
      }
    } catch (e) {
      debugPrint('Error exporting logs: $e');
      return null;
    }
  }

  @override
  Future<bool> shareLogs({String? subject, BuildContext? context}) async {
    try {
      final file = await _ensureFile();
      if (file == null || !await file.exists()) return false;

      final content = await file.readAsString();
      if (content.trim().isEmpty) return false;

      final xFile = XFile(file.path, mimeType: 'text/plain', name: LogStorage.defaultLogFileName);

      Rect? sharePositionOrigin;
      if (context != null && context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
        }
      }

      final result = await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'The Realty Bazaar Diagnostic Logs',
        sharePositionOrigin: sharePositionOrigin,
      );

      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Error sharing logs: $e');
      return false;
    }
  }

  @override
  Future<int> getLogSizeBytes() async {
    try {
      final file = await _ensureFile();
      if (file == null || !await file.exists()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> getLogCount() async {
    try {
      final file = await _ensureFile();
      if (file == null || !await file.exists()) return 0;
      final text = await file.readAsString();
      if (text.trim().isEmpty) return 0;
      return _entrySeparator.allMatches(text).length;
    } catch (_) {
      return 0;
    }
  }
}

LogStorage createPlatformLogStorage() => LogStorageImplementation();
