import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class PropertyVisitService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final PropertyVisitService _instance = PropertyVisitService._internal();

  factory PropertyVisitService({SupabaseClient? client}) {
    if (client != null) return PropertyVisitService._internal(client: client);
    return _instance;
  }

  PropertyVisitService._internal({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<PaginatedResponse<PropertyVisitModel>> fetchVisits({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? status,
    String? brokerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return getPaginated<PropertyVisitModel>(
      table: 'property_visits',
      select: '*, broker_id(*), property_id(*)',
      fromJson: PropertyVisitModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'client_name',
      searchQuery: search,
      sortBy: sortBy ?? 'created_at',
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (status != null && status != 'All') 'status': status,
        if (brokerId != null) 'broker_id': brokerId,
      },
    );
  }

  Future<PropertyVisitModel> getVisitById(String id) async {
    try {
      final response = await _client
          .from('property_visits')
          .select('*, broker_id(*), property_id(*)')
          .eq('id', id)
          .single();
      return PropertyVisitModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Error fetching visit');
    }
  }

  Future<void> updateVisitStatus(String id, String status, {String? notes}) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (notes != null) payload['notes'] = notes;
      await _client.from('property_visits').update(payload).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
