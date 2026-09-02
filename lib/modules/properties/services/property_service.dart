import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class PropertyService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final PropertyService _instance = PropertyService._internal();

  factory PropertyService({SupabaseClient? client}) {
    if (client != null) return PropertyService._internal(client: client);
    return _instance;
  }

  PropertyService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch paginated list of properties with search and filters.
  Future<PaginatedResponse<PropertyModel>> fetchProperties({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? propertyType,
    String? listingType,
    String? propertyStatus,
    String? constructionStatus,
    String? furnishingStatus,
    String? facing,
    double? priceMin,
    double? priceMax,
    bool? isActive,
  }) async {
    final Map<String, dynamic> filters = {
      'is_deleted': false,
      if (isActive != null) 'is_active': isActive,
      if (propertyType != null && propertyType != 'All') 'property_type': propertyType,
      if (listingType != null && listingType != 'All') 'listing_type': listingType,
      if (propertyStatus != null && propertyStatus != 'All') 'property_status': propertyStatus,
      if (constructionStatus != null && constructionStatus != 'All')
        'construction_status': constructionStatus,
      if (furnishingStatus != null && furnishingStatus != 'All') 'furnishing_status': furnishingStatus,
      if (facing != null && facing != 'All') 'facing': facing,
    };

    if (priceMin != null || priceMax != null) {
      final priceFilter = <String, dynamic>{};
      if (priceMin != null) priceFilter['gte'] = priceMin;
      if (priceMax != null) priceFilter['lte'] = priceMax;
      filters['price'] = priceFilter;
    }

    return getPaginated<PropertyModel>(
      table: 'properties',
      select: '*, address_id(*), broker_id(*, address_id(*))',
      fromJson: PropertyModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'search_text',
      searchQuery: search,
      sortBy: sortBy,
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: filters,
    );
  }

  /// Update property status.
  Future<void> updatePropertyStatus(String id, PropertyStatus status) async {
    try {
      await _client.from('properties').update({'property_status': status.apiValue}).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft-delete or hard-delete a property.
  Future<void> deleteProperty({required String id, bool hardDelete = false}) async {
    try {
      if (hardDelete) {
        await _client.from('properties').delete().eq('id', id);
      } else {
        await _client
            .from('properties')
            .update({'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Publish or update property via publish_property RPC.
  Future<PropertyModel?> saveProperty(PropertyModel property, {bool isEdit = false}) async {
    try {
      final payload = property.toJson();
      final response = await _client.rpc(
        'publish_property',
        params: {'p_property': payload, 'p_is_edit': isEdit},
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['success'] == true) {
          if (response['property'] != null) {
            final returnedJson = response['property'] as Map<String, dynamic>;
            AddressModel? parsedAddr;
            String? addrId;
            if (returnedJson['address_id'] != null) {
              if (returnedJson['address_id'] is Map<String, dynamic>) {
                parsedAddr = AddressModel.fromJson(returnedJson['address_id']);
                addrId = parsedAddr.id;
              } else {
                addrId = returnedJson['address_id'].toString();
              }
            }
            final merged = property.copyWith(
              id: returnedJson['id']?.toString(),
              addressId: addrId,
              address: parsedAddr ?? property.address,
            );
            return merged;
          }
          return property;
        }
        final errorMsg = response['error']?.toString() ?? 'Server error';
        throw Exception(errorMsg);
      }
      return property;
    } catch (e) {
      throw handleException(e, 'Failed to save property');
    }
  }

  /// Get property by ID.
  Future<PropertyModel> getPropertyById({required String id}) async {
    try {
      final response = await _client
          .from('properties')
          .select('*, address_id(*), broker_id(*)')
          .eq('id', id)
          .single();
      return PropertyModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Unexpected error fetching property');
    }
  }
}
