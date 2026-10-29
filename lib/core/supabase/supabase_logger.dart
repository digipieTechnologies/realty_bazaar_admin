import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_realty_bazaar/core/logging/app_log_service.dart';

class SupabaseLoggerClient extends BaseClient {
  SupabaseLoggerClient({
    Client? inner,
    this.enableRequestBody = true,
    this.enableResponseBody = true,
    this.maxBodyLength = 4000,
  }) : _inner = inner ?? Client();

  final Client _inner;

  final bool enableRequestBody;
  final bool enableResponseBody;
  final int maxBodyLength;

  static final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.off,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      noBoxingByDefault: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static const _allowedHeaders = {
    'x-client-info',
    'x-supabase-client-platform',
  };

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final requestId = _requestId();

    try {
      if (kDebugMode) {
        _logRequest(requestId, request);
      }

      final response = await _inner.send(request);
      final bytes = await response.stream.toBytes();

      stopwatch.stop();

      if (kDebugMode) {
        _logResponse(
          requestId,
          request,
          response,
          bytes,
          stopwatch.elapsedMilliseconds,
        );
      }

      // Intercept 401 or "Authentication required." errors
      if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        try {
          final bodyString = utf8.decode(bytes);
          if (bodyString.contains('Authentication required.')) {
            final decoded = jsonDecode(bodyString);
            if (decoded is Map && decoded['message'] == 'Authentication required.') {
              _handleUnauthorized();
            }
          }
        } catch (_) {
          // Ignored
        }
      }

      if (response.statusCode >= 400) {
        String? errorBody;
        try {
          errorBody = utf8.decode(bytes);
        } catch (_) {}
        AppLogService.instance.logError(
          'Supabase HTTP ${response.statusCode}: ${request.method} ${_formatQueryParams(request.url)}'
          '${errorBody != null ? '\nResponse: $errorBody' : ''}',
          tag: 'SupabaseHTTP',
        );
      }

      return StreamedResponse(
        ByteStream.fromBytes(bytes),
        response.statusCode,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        contentLength: response.contentLength,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogService.instance.logError(
        'Supabase Network Failure: ${request.method} ${_formatQueryParams(request.url)} - $e',
        stack: stackTrace,
        tag: 'SupabaseNetwork',
      );

      if (kDebugMode) {
        // Formats the URL here as well in case the initialization or execution crashes
        final formattedUrl = _formatQueryParams(request.url);

        _logger.e(
          '[$requestId] ${request.method} $formattedUrl '
          '(${stopwatch.elapsedMilliseconds}ms)\n$e',
          error: e,
          stackTrace: stackTrace,
        );
      }

      rethrow;
    }
  }

  void _handleUnauthorized() {
    Future.microtask(() async {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Error signing out on auth failure: $e');
      }
    });
  }

  void _logRequest(String id, BaseRequest request) {
    final formattedUrl = _formatQueryParams(request.url);
    final buffer = StringBuffer()..writeln('[$id] ${request.method} $formattedUrl');

    if (request.headers.isNotEmpty) {
      final headersToLog =
          request.headers.entries.where((e) => _allowedHeaders.contains(e.key.toLowerCase())).toList();

      if (headersToLog.isNotEmpty) {
        buffer.writeln('Headers:');
        for (final entry in headersToLog) {
          buffer.writeln('  ${entry.key}: ${entry.value}');
        }
      }
    }

    if (enableRequestBody && request is Request) {
      final body = _formatBody(request.body);

      if (body.isNotEmpty) {
        buffer
          ..writeln('Body:')
          ..writeln(_truncate(body));
      }
    }

    _logger.i(buffer.toString());
  }

  void _logResponse(
    String id,
    BaseRequest request,
    StreamedResponse response,
    List<int> bytes,
    int durationMs,
  ) {
    final formattedUrl = _formatQueryParams(request.url);
    final buffer = StringBuffer()
      ..writeln(
        '[$id] ${response.statusCode} ${request.method} $formattedUrl (${durationMs}ms)',
      );

    if (enableResponseBody) {
      final body = _decodeBody(bytes);

      if (body.isNotEmpty) {
        buffer
          ..writeln('Body:')
          ..writeln(_truncate(body));
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _logger.d(buffer.toString());
    } else {
      _logger.w(buffer.toString());
    }
  }

  /// Custom utility to extract query variables and separate them using a pipeline delimiter
  String _formatQueryParams(Uri url) {
    if (!url.hasQuery) return url.path;

    final params = url.queryParameters;

    final separatedParams = params.entries.map((e) => '${e.key}=${e.value}').join('|');

    return '${url.path} [$separatedParams]';
  }

  String _decodeBody(List<int> bytes) {
    try {
      return _formatBody(utf8.decode(bytes));
    } catch (_) {
      return '[Binary Data]';
    }
  }

  String _formatBody(String body) {
    if (body.trim().isEmpty) {
      return '';
    }

    try {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }

  String _truncate(String text) {
    return text;
  }

  String _requestId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36).substring(6);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
