// File: lib/modules/leads/services/lead_service.dart
// Purpose: Network service managing social leads fetching via get_social_leads RPC, single lead retrieval, creation, updating, reassignment, and soft deletion.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination_model.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/broker_model.dart';
import '../../../models/social_lead_model.dart';

class LeadService {
  final SupabaseClient _client;

  static final LeadService _instance = LeadService._internal();

  factory LeadService({SupabaseClient? client}) {
    if (client != null) return LeadService._internal(client: client);
    return _instance;
  }

  LeadService._internal({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  /// Fetches paginated social leads via the get_social_leads RPC.
  /// When [brokerId] is null or 'all', leads across all brokers are returned.
  Future<PaginatedResponse<SocialLeadModel>> fetchLeads({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
    List<String>? platforms,
    String? brokerId,
  }) async {
    try {
      final sanitizedBrokerId = (brokerId != null && brokerId.isNotEmpty && brokerId != 'all') ? brokerId : null;

      final response = await _client.rpc(
        'get_social_leads',
        params: {
          'p_broker_id': sanitizedBrokerId,
          'p_page': page,
          'p_limit': pageSize,
          'p_search_query': searchQuery ?? '',
          'p_platforms': (platforms != null && platforms.isNotEmpty) ? platforms : null,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        final rawList = (response['data'] as List?) ?? [];
        final items = rawList.map((json) => SocialLeadModel.fromJson(json)).toList();

        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
        final totalItems = int.tryParse(pagination['total_items']?.toString() ?? '0') ?? items.length;
        final totalPages = int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;

        return PaginatedResponse(
          items: items,
          pagination: PaginationMetadata(
            page: page,
            pageSize: pageSize,
            total: totalItems,
            totalPages: totalPages,
          ),
        );
      }

      return PaginatedResponse(
        items: [],
        pagination: PaginationMetadata(page: page, pageSize: pageSize, total: 0, totalPages: 1),
      );
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] PostgrestException in fetchLeads: ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error in fetchLeads: $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Fetches a single lead by its unique ID, joining broker, social post, property, and address.
  Future<SocialLeadModel?> fetchLeadById(String leadId) async {
    try {
      final response = await _client
          .from('social_leads')
          .select('*, broker:brokers(*), social_post:social_posts(*, property:properties(*, address:addresses(*)))')
          .eq('id', leadId.trim())
          .maybeSingle();

      if (response != null) {
        return SocialLeadModel.fromJson(response);
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] Error fetching lead by ID ($leadId): ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error fetching lead by ID ($leadId): $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Creates a new lead manually in the social_leads table.
  Future<SocialLeadModel> createLead({
    required String userName,
    required String phone,
    required String propertyDetails,
    String? notes,
    String? brokerId,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '').trim();
      final sanitizedBrokerId = (brokerId != null && brokerId.isNotEmpty && brokerId != 'all') ? brokerId : null;

      final response = await _client
          .from('social_leads')
          .insert({
            'user_name': userName.trim(),
            'phone': cleanPhone,
            'phone_country_code': '91',
            'phone_country_iso': 'IN',
            'property_details': propertyDetails.trim(),
            'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
            'broker_id': sanitizedBrokerId,
            'is_deleted': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('*, broker:brokers(*)')
          .single();

      return SocialLeadModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] PostgrestException creating lead: ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error creating lead: $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Updates details of an existing lead.
  Future<void> updateLead(SocialLeadModel lead) async {
    if (lead.id == null) {
      throw ApiException('Lead ID cannot be null for update.', code: 400);
    }

    try {
      final payload = <String, dynamic>{
        'user_name': lead.userName.trim(),
        'phone': lead.phone.replaceAll(RegExp(r'\D'), '').trim(),
        'property_details': lead.propertyDetails?.trim(),
        'notes': lead.notes?.trim(),
        'broker_id': lead.resolvedBrokerId,
      };

      await _client.from('social_leads').update(payload).eq('id', lead.id!);
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] PostgrestException updating lead: ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error updating lead: $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Reassigns an existing lead to a different broker and optionally updates property details.
  Future<void> reassignBroker(String leadId, String? newBrokerId, {String? propertyDetails}) async {
    try {
      final sanitizedBrokerId =
          (newBrokerId != null && newBrokerId.isNotEmpty && newBrokerId != 'all') ? newBrokerId : null;

      final payload = <String, dynamic>{
        'broker_id': sanitizedBrokerId,
        if (propertyDetails != null && propertyDetails.isNotEmpty) 'property_details': propertyDetails,
      };

      await _client.from('social_leads').update(payload).eq('id', leadId);
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] PostgrestException reassigning broker: ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error reassigning broker: $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Soft deletes a lead by setting is_deleted = true and deleted_at = now().
  Future<void> deleteLead(String leadId) async {
    try {
      await _client.from('social_leads').update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', leadId);
    } on PostgrestException catch (e) {
      debugPrint('[LeadService] PostgrestException soft-deleting lead: ${e.message}');
      throw ApiException(e.message, code: 500);
    } catch (e) {
      debugPrint('[LeadService] Error soft-deleting lead: $e');
      throw ApiException(e.toString(), code: 500);
    }
  }

  /// Fetches a lightweight list of all active brokers for dropdown selectors.
  Future<List<BrokerModel>> fetchBrokersForFilter() async {
    try {
      final response = await _client
          .from('brokers')
          .select('id, business_name')
          .order('business_name', ascending: true);

      return (response as List).map((json) => BrokerModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LeadService] Error fetching brokers for filter: $e');
      return [];
    }
  }
}
