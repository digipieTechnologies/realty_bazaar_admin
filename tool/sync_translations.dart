#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final scriptUri = Platform.script;
  final String projectRoot;
  if (scriptUri.scheme == 'file') {
    projectRoot = File(scriptUri.toFilePath()).parent.parent.path;
  } else {
    projectRoot = Directory.current.path;
  }

  final enPath = '$projectRoot/${translationFiles['en']!}';
  print('Loading source of truth: $enPath');
  final enJson = await loadJson(enPath);

  if (enJson.isEmpty) {
    print('Error: en.json is empty or not found at $enPath.');
    exitCode = 1;
    return;
  }

  for (final entry in translationFiles.entries) {
    final lang = entry.key;
    final relativePath = entry.value;
    final path = '$projectRoot/$relativePath';

    if (lang == 'en') continue;

    print('\n----------------------------------------');
    print('Syncing $lang ($path) with en.json...');

    final targetJson = await loadJson(path);
    final stats = SyncStats();
    final syncedJson = await syncMap(enJson, targetJson, lang, stats);

    await saveJson(path, syncedJson);
    print('Finished syncing $lang. Saved to $path.');
    print('Statistics for $lang:');
    print('  - Added (Translated): ${stats.added}');
    print('  - Deleted (Obsolete): ${stats.deleted}');
    print('  - Untouched (Existing): ${stats.untouched}');
    if (stats.failed > 0) {
      print('  - Failed: ${stats.failed}');
    }
  }

  print('\n----------------------------------------');
  print('All translation files are now synchronized!');
}

class SyncStats {
  int added = 0;
  int deleted = 0;
  int untouched = 0;
  int failed = 0;
}

final translationFiles = {
  'en': 'assets/translations/en.json',
  'gu': 'assets/translations/gu.json',
  'hi': 'assets/translations/hi.json',
};

Future<String> translate(String text, String lang) async {
  // If the text contains placeholders like {name} or {count}, we should be careful.
  // Google Translate might translate them or change their formatting.
  // We can pass them as is, but we should warn the user.
  final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$lang&dt=t&q=${Uri.encodeComponent(text)}');

  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    return decoded[0][0][0];
  } finally {
    httpClient.close();
  }
}

Future<Map<String, dynamic>> loadJson(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return {};
  }
  final content = await file.readAsString();
  return jsonDecode(content);
}

Future<void> saveJson(String path, Map<String, dynamic> data) async {
  final file = File(path);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(data)}\n');
}

Future<Map<String, dynamic>> syncMap(
  Map<String, dynamic> source,
  Map<String, dynamic> target,
  String lang,
  SyncStats stats,
) async {
  final result = <String, dynamic>{};

  // Identify deleted (obsolete) keys
  for (final key in target.keys) {
    if (!source.containsKey(key)) {
      stats.deleted++;
      print('  Obsolete key found in $lang (will be deleted): "$key"');
    }
  }

  for (final key in source.keys) {
    final sourceVal = source[key];
    final targetVal = target[key];

    if (sourceVal is Map<String, dynamic>) {
      final targetMap = (targetVal is Map<String, dynamic>) ? targetVal : <String, dynamic>{};
      result[key] = await syncMap(sourceVal, targetMap, lang, stats);
    } else if (sourceVal is String) {
      if (targetVal is String && targetVal.trim().isNotEmpty) {
        // Already translated/filled
        result[key] = targetVal;
        stats.untouched++;
      } else {
        // Needs translation
        print('Syncing key: "$key" -> translating "$sourceVal" to $lang...');
        try {
          final translated = await translate(sourceVal, lang);
          result[key] = translated;
          print('  Result: "$translated"');
          stats.added++;
        } catch (e) {
          print('  Error translating "$sourceVal": $e');
          result[key] = targetVal ?? ""; // fallback
          stats.failed++;
        }
        // Small delay to avoid rate limiting
        await Future.delayed(Duration(milliseconds: 300));
      }
    } else {
      result[key] = sourceVal;
    }
  }

  return result;
}
