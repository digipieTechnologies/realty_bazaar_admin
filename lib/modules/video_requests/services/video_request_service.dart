import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class VideoRequestService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final VideoRequestService _instance = VideoRequestService._internal();

  factory VideoRequestService({SupabaseClient? client}) {
    if (client != null) return VideoRequestService._internal(client: client);
    return _instance;
  }

  VideoRequestService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch paginated list of video requests with search & filters.
  Future<PaginatedResponse<VideoRequestModel>> fetchVideoRequests({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? status,
    String? adminApprovalStatus,
  }) async {
    return getPaginated<VideoRequestModel>(
      table: 'video_requests',
      select: '*, property_id(*), broker_id(*)',
      fromJson: VideoRequestModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'notes',
      // Search based on request notes/instructions
      searchQuery: search,
      sortBy: sortBy,
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (status != null && status != 'All') 'status': status,
        if (adminApprovalStatus != null && adminApprovalStatus != 'All')
          'admin_approval_status': adminApprovalStatus,
      },
    );
  }

  /// Create a new video request.
  Future<String> createVideoRequest({
    required String propertyId,
    required String brokerId,
    String? notes,
  }) async {
    try {
      final response = await _client
          .from('video_requests')
          .insert({
            'property_id': propertyId,
            'broker_id': brokerId,
            'status': 'pending',
            'admin_approval_status': 'pending',
            'notes': notes,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing video request notes.
  Future<void> updateVideoRequest(VideoRequestModel request) async {
    if (request.id == null) throw Exception('Request ID cannot be null for update.');
    try {
      final payload = <String, dynamic>{
        'notes': request.notes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('video_requests').update(payload).eq('id', request.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Update video request status or admin approval details.
  Future<void> updateApprovalStatus(
    String id, {
    required String adminApprovalStatus,
    required String status,
    String? notes,
    String? adminCancelReason,
  }) async {
    try {
      final payload = <String, dynamic>{
        'admin_approval_status': adminApprovalStatus,
        'status': status,
        if (notes != null) 'notes': notes,
        if (adminCancelReason != null) 'admin_cancel_reason': adminCancelReason,
        if (status == 'completed') 'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('video_requests').update(payload).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a video request.
  Future<void> deleteVideoRequest(String id) async {
    try {
      await _client.from('video_requests').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Get video request by ID.
  Future<VideoRequestModel> getVideoRequestById(String id) async {
    try {
      final response = await _client
          .from('video_requests')
          .select('*, property_id(*), broker_id(*)')
          .eq('id', id)
          .single();
      return VideoRequestModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Unexpected error fetching video request');
    }
  }
}
