// File: lib/core/services/attachment_service.dart
// Purpose: R2 attachments & cover image service via Supabase Edge Function r2-upload.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/attachment_model.dart';
import '../network/api_exception.dart';
import '../network/base_supabase_service.dart';

class AttachmentService extends BaseSupabaseService {
  static const String _functionName = 'r2-upload';
  final SupabaseClient _client;

  static final AttachmentService _instance = AttachmentService._internal();

  factory AttachmentService({SupabaseClient? client}) {
    if (client != null) return AttachmentService._internal(client: client);
    return _instance;
  }

  AttachmentService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch attachments for entity.
  Future<List<AttachmentModel>> getAttachments({required String entityType, required String entityId}) async {
    try {
      final response = await _client
          .from('attachments')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => AttachmentModel.fromJson(json)).toList();
    } catch (e) {
      throw handleException(e, 'Failed to fetch attachments');
    }
  }

  /// Upload cover image via r2-upload Edge Function.
  Future<AttachmentModel> setCoverImageGeneric({
    required String table,
    required String entityId,
    required String fileName,
    required Uint8List bytes,
    String column = 'cover_image',
    String? oldR2Key,
  }) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final mimeType = _getMimeType(ext);

      // 1. Get presigned upload URL from Edge Function
      final presignResult = await _client.functions.invoke(
        _functionName,
        queryParameters: {'action': 'presign'},
        body: {
          'entityType': table,
          'entityId': entityId,
          'fileName': fileName,
          'mimeType': mimeType,
          'fileSize': bytes.length,
          'skipDbInsert': true,
          'oldR2Key': oldR2Key,
        },
      );

      if (presignResult.status != 200 || presignResult.data == null) {
        throw ApiException('Failed to get presigned upload URL');
      }

      final presignedUrl = presignResult.data['presignedUrl'] as String;
      final publicUrl = presignResult.data['publicUrl'] as String;
      final r2Key = presignResult.data['r2Key'] as String?;

      // 2. Direct PUT upload to Cloudflare R2
      final putResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': mimeType, 'Content-Length': bytes.length.toString()},
        body: bytes,
      );

      if (putResponse.statusCode != 200 && putResponse.statusCode != 204) {
        throw ApiException('R2 direct upload failed (${putResponse.statusCode})');
      }

      final attachment = AttachmentModel(url: publicUrl, type: ext, r2Key: r2Key, createdAt: DateTime.now());

      // 3. Update entity table column with JSON metadata
      await _client.from(table).update({column: attachment.toJson()}).eq('id', entityId);

      return attachment;
    } catch (e) {
      throw handleException(e, 'Failed to upload cover image');
    }
  }

  /// Remove cover image and delete object from R2 via Edge Function.
  Future<void> removeCoverImageGeneric({
    required String table,
    required String entityId,
    String column = 'cover_image',
    String? r2Key,
  }) async {
    try {
      if (r2Key != null && r2Key.isNotEmpty) {
        await _client.functions.invoke(
          _functionName,
          queryParameters: {'action': 'delete'},
          body: {'r2Key': r2Key},
        );
      }

      await _client.from(table).update({column: null}).eq('id', entityId);
    } catch (e) {
      throw handleException(e, 'Failed to remove cover image');
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
