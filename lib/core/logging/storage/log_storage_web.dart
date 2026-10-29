// File: lib/core/logging/storage/log_storage_web.dart
// Purpose: Web implementation of LogStorage using browser IndexedDB (with fallback), Blob URL file downloads, and clipboard sharing.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'log_storage.dart';

class LogStorageImplementation implements LogStorage {
  static const String _dbName = 'TheRealtyBazaarLogs';
  static const String _storeName = 'diagnostic_logs';
  static const int _dbVersion = 1;
  static const String _entrySeparator =
      '\n================================================================================\n';

  web.IDBDatabase? _db;
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final idb = web.window.indexedDB;
      final request = idb.open(_dbName, _dbVersion);

      final completer = Completer<void>();

      request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
        final db = request.result as web.IDBDatabase;
        if (!db.objectStoreNames.contains(_storeName)) {
          // Key path 'id' auto-incrementing integer
          final options = web.IDBObjectStoreParameters(keyPath: 'id'.toJS, autoIncrement: true);
          final store = db.createObjectStore(_storeName, options);
          store.createIndex('timestamp', 'timestamp'.toJS);
        }
      }.toJS;

      request.onsuccess = (web.Event event) {
        _db = request.result as web.IDBDatabase;
        _initialized = true;
        completer.complete();
      }.toJS;

      request.onerror = (web.Event event) {
        debugPrint('IndexedDB open error, using localStorage fallback');
        _initialized = true;
        completer.complete();
      }.toJS;

      await completer.future;
    } catch (e) {
      debugPrint('Failed to open IndexedDB: $e');
      _initialized = true;
    }

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<web.IDBDatabase?> _getDb() async {
    if (!_initCompleter.isCompleted) {
      await initialize();
    }
    return _db;
  }

  @override
  Future<void> appendLog(String formattedEntry) async {
    final db = await _getDb();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (db != null) {
      try {
        final tx = db.transaction(_storeName.toJS, 'readwrite');
        final store = tx.objectStore(_storeName);

        final entryMap = {'content': formattedEntry, 'timestamp': timestamp};
        store.add(entryMap.jsify()!);

        // Check and trim count/size
        await _trimIndexedDb(store, tx);
        return;
      } catch (e) {
        debugPrint('IndexedDB appendLog failed: $e, falling back to localStorage');
      }
    }

    // Fallback: localStorage
    _fallbackAppend(formattedEntry);
  }

  Future<void> _trimIndexedDb(web.IDBObjectStore store, web.IDBTransaction tx) async {
    try {
      final countReq = store.count();
      final completer = Completer<int>();
      countReq.onsuccess = (web.Event e) {
        final count = (countReq.result as JSNumber).toDartInt;
        completer.complete(count);
      }.toJS;
      countReq.onerror = (web.Event e) {
        completer.complete(0);
      }.toJS;

      final count = await completer.future;
      if (count > LogStorage.maxLogEntries) {
        final deleteCount = count - LogStorage.maxLogEntries;
        final cursorReq = store.openCursor();
        int deleted = 0;
        cursorReq.onsuccess = (web.Event e) {
          final cursor = cursorReq.result as web.IDBCursorWithValue?;
          if (cursor != null && deleted < deleteCount) {
            cursor.delete();
            deleted++;
            cursor.continue_();
          }
        }.toJS;
      }
    } catch (_) {}
  }

  void _fallbackAppend(String formattedEntry) {
    try {
      const storageKey = 'realty_bazaar_app_logs';
      final existing = web.window.localStorage.getItem(storageKey) ?? '';
      final newBlock = '$formattedEntry$_entrySeparator$existing';
      if (newBlock.length > LogStorage.maxLogSizeBytes) {
        final trimmed = newBlock.substring(0, LogStorage.maxLogSizeBytes);
        web.window.localStorage.setItem(storageKey, trimmed);
      } else {
        web.window.localStorage.setItem(storageKey, newBlock);
      }
    } catch (_) {}
  }

  @override
  Future<String> readLogs() async {
    final db = await _getDb();
    if (db != null) {
      try {
        final tx = db.transaction(_storeName.toJS, 'readonly');
        final store = tx.objectStore(_storeName);
        final request = store.getAll();

        final completer = Completer<String>();
        request.onsuccess = (web.Event event) {
          final jsArray = request.result as JSArray;
          final dartList = jsArray.toDart;
          final entries = <String>[];

          for (final item in dartList) {
            try {
              if (item != null) {
                if (item.isA<JSString>()) {
                  final jsonStr = (item as JSString).toDart;
                  final decoded = json.decode(jsonStr) as Map<String, dynamic>;
                  if (decoded.containsKey('content')) {
                    entries.add(decoded['content'] as String);
                  }
                } else {
                  final dartObj = (item as JSObject).dartify();
                  if (dartObj is Map && dartObj.containsKey('content')) {
                    entries.add(dartObj['content'].toString());
                  }
                }
              }
            } catch (_) {}
          }

          // Prepend newest entries first (reverse chronological order)
          final reversed = entries.reversed.toList();
          completer.complete(reversed.join(_entrySeparator));
        }.toJS;

        request.onerror = (web.Event event) {
          completer.complete('');
        }.toJS;

        return await completer.future;
      } catch (e) {
        debugPrint('IndexedDB readLogs failed: $e');
      }
    }

    const storageKey = 'realty_bazaar_app_logs';
    return web.window.localStorage.getItem(storageKey) ?? '';
  }

  @override
  Future<void> clearLogs() async {
    final db = await _getDb();
    if (db != null) {
      try {
        final tx = db.transaction(_storeName.toJS, 'readwrite');
        final store = tx.objectStore(_storeName);
        store.clear();
      } catch (e) {
        debugPrint('IndexedDB clearLogs failed: $e');
      }
    }
    const storageKey = 'realty_bazaar_app_logs';
    web.window.localStorage.removeItem(storageKey);
  }

  @override
  Future<String?> exportLogs({String? suggestedFileName}) async {
    try {
      final logs = await readLogs();
      if (logs.trim().isEmpty) return null;

      final fileName = suggestedFileName ?? 'realty_bazaar_errors_${DateTime.now().millisecondsSinceEpoch}.log';

      // Create Blob and trigger browser download via HTMLAnchorElement
      final bytes = utf8.encode(logs);
      final jsUint8Array = bytes.toJS;
      final blobParts = [jsUint8Array].toJS;
      final blobOptions = web.BlobPropertyBag(type: 'text/plain;charset=utf-8');
      final blob = web.Blob(blobParts, blobOptions);

      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);

      return fileName;
    } catch (e) {
      debugPrint('Web exportLogs error: $e');
      return null;
    }
  }

  @override
  Future<bool> shareLogs({String? subject, BuildContext? context}) async {
    try {
      final logs = await readLogs();
      if (logs.trim().isEmpty) return false;

      // Copy logs to web clipboard
      await Clipboard.setData(ClipboardData(text: logs));
      return true;
    } catch (e) {
      debugPrint('Web shareLogs error: $e');
      return false;
    }
  }

  @override
  Future<int> getLogSizeBytes() async {
    final logs = await readLogs();
    return utf8.encode(logs).length;
  }

  @override
  Future<int> getLogCount() async {
    final logs = await readLogs();
    if (logs.trim().isEmpty) return 0;
    return _entrySeparator.allMatches(logs).length + 1;
  }
}

LogStorage createPlatformLogStorage() => LogStorageImplementation();
