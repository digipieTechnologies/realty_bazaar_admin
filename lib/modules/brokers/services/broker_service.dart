import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class BrokerService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final BrokerService _instance = BrokerService._internal();

  factory BrokerService({SupabaseClient? client}) {
    if (client != null) return BrokerService._internal(client: client);
    return _instance;
  }

  BrokerService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch list of all brokers with optional pagination, search, and status/plan filters.
  Future<PaginatedResponse<BrokerModel>> fetchBrokers({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? plan,
    String? onboardingStatus,
    bool? isActive,
  }) async {
    return getPaginated<BrokerModel>(
      table: 'brokers',
      select: '*, address_id(*)',
      fromJson: BrokerModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'search_text',
      searchQuery: search,
      sortBy: sortBy,
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        'is_active': ?isActive,
        if (plan != null && plan != 'All') 'plan': plan,
        if (onboardingStatus != null && onboardingStatus != 'All') 'onboarding_status': onboardingStatus,
      },
    );
  }

  /// Create a new brokerage account.
  Future<String> createBroker({
    required String businessName,
    String plan = 'Free',
    String onboardingStatus = 'pending',
    bool isActive = true,
  }) async {
    try {
      final response = await _client
          .from('brokers')
          .insert({
            'business_name': businessName.trim(),
            'plan': plan,
            'onboarding_status': onboardingStatus,
            'is_active': isActive,
            'created_at': DateTime.now().toUtc().toIso8601String(),
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

  /// Update an existing brokerage record and its linked address.
  Future<void> updateBroker(BrokerModel broker) async {
    if (broker.id == null) throw Exception('Broker ID cannot be null for update.');
    try {
      String? addressId = broker.addressId?.id;
      final addressData = broker.addressId;

      if (addressData != null) {
        if (addressId == null) {
          final addressInsert = await _client
              .from('addresses')
              .insert({
                'full_address': addressData.fullAddress?.trim(),
                'city': addressData.city?.trim(),
                'state': addressData.state?.trim(),
                'pincode': addressData.pincode?.trim(),
                'country': addressData.country?.trim(),
                'landmark': addressData.landmark?.trim(),
                'entity_type': 'broker',
                'entity_id': broker.id,
              })
              .select('id')
              .single();
          addressId = addressInsert['id'] as String;
        } else {
          await _client
              .from('addresses')
              .update({
                'full_address': addressData.fullAddress?.trim(),
                'city': addressData.city?.trim(),
                'state': addressData.state?.trim(),
                'pincode': addressData.pincode?.trim(),
                'country': addressData.country?.trim(),
                'landmark': addressData.landmark?.trim(),
              })
              .eq('id', addressId);
        }
      }

      final payload = <String, dynamic>{
        if (broker.businessName != null) 'business_name': broker.businessName!.trim(),
        if (broker.onboardingStatus != null) 'onboarding_status': broker.onboardingStatus,
        if (broker.isActive != null) 'is_active': broker.isActive,
        if (broker.autoApproveVideoRequests != null)
          'auto_approve_video_requests': broker.autoApproveVideoRequests,
        if (addressId != null) 'address_id': addressId,
      };

      await _client.from('brokers').update(payload).eq('id', broker.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle active status of a brokerage account.
  Future<void> toggleBrokerStatus(String brokerId, bool isActive) async {
    try {
      await _client.from('brokers').update({'is_active': isActive}).eq('id', brokerId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft-delete or hard-delete a brokerage account.
  Future<void> deleteBroker({required String brokerId, bool hardDelete = false}) async {
    try {
      if (hardDelete) {
        await _client.from('brokers').delete().eq('id', brokerId);
      } else {
        await _client
            .from('brokers')
            .update({'is_active': false, 'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', brokerId);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a broker by ID.
  Future<BrokerModel> getBrokerById({required String id}) async {
    try {
      final response = await _client.from('brokers').select('*, address_id(*)').eq('id', id).single();
      return BrokerModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Unexpected error fetching broker');
    }
  }

  /// Get properties owned by a specific broker.
  Future<List<PropertyModel>> getPropertiesForBroker(String brokerId) async {
    try {
      final response = await _client
          .from('properties')
          .select('*, address_id(*)')
          .eq('broker_id', brokerId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);
      return (response as List).map((e) => PropertyModel.fromJson(e)).toList();
    } catch (e) {
      throw handleException(e, 'Failed to fetch properties for broker');
    }
  }

  /// Get social posts created by a specific broker.
  Future<List<SocialPostModel>> getSocialPostsForBroker(String brokerId) async {
    try {
      final response = await _client
          .from('social_posts')
          .select()
          .eq('broker_id', brokerId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => SocialPostModel.fromJson(e)).toList();
    } catch (e) {
      throw handleException(e, 'Failed to fetch social posts for broker');
    }
  }
}
