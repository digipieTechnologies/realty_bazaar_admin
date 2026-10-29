import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class SocialPostService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final SocialPostService _instance = SocialPostService._internal();

  factory SocialPostService({SupabaseClient? client}) {
    if (client != null) return SocialPostService._internal(client: client);
    return _instance;
  }

  SocialPostService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch paginated list of social posts with search & filters.
  Future<PaginatedResponse<SocialPostModel>> fetchSocialPosts({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? platform,
  }) async {
    return getPaginated<SocialPostModel>(
      table: 'social_posts',
      select: '*, property_id(*), broker_id(*)',
      fromJson: SocialPostModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'caption',
      searchQuery: search,
      sortBy: sortBy,
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (platform != null && platform != 'All') 'platform': platform,
      },
    );
  }

  /// Create a new social post.
  Future<String> createSocialPost({
    required String brokerId,
    required String propertyId,
    required String platform,
    required String caption,
    List<String> mediaUrls = const [],
  }) async {
    try {
      final response = await _client
          .from('social_posts')
          .insert({
            'broker_id': brokerId,
            'property_id': propertyId,
            'platform': platform,
            'caption': caption,
            'media_urls': mediaUrls,
            'published_at': DateTime.now().toUtc().toIso8601String(),
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

  /// Update an existing social post details.
  Future<void> updateSocialPost(SocialPostModel post) async {
    if (post.id == null) throw Exception('Post ID cannot be null for update.');
    try {
      final payload = <String, dynamic>{
        'caption': post.caption,
        'platform': post.platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('social_posts').update(payload).eq('id', post.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a social post.
  Future<void> deleteSocialPost(String id) async {
    try {
      await _client.from('social_posts').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a social post by ID.
  Future<SocialPostModel> getSocialPostById(String id) async {
    try {
      final response = await _client
          .from('social_posts')
          .select('*, property_id(*), broker_id(*)')
          .eq('id', id)
          .single();
      return SocialPostModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Unexpected error fetching social post');
    }
  }
}
