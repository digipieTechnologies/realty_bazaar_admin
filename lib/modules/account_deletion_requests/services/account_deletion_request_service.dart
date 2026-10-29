import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class AccountDeletionRequestService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final AccountDeletionRequestService _instance =
      AccountDeletionRequestService._internal();

  factory AccountDeletionRequestService({SupabaseClient? client}) {
    if (client != null) return AccountDeletionRequestService._internal(client: client);
    return _instance;
  }

  AccountDeletionRequestService._internal({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<PaginatedResponse<AccountDeletionRequestModel>> fetchRequests({
    int? page,
    int? pageSize,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    return getPaginated<AccountDeletionRequestModel>(
      table: 'account_deletion_requests',
      select: '*',
      fromJson: AccountDeletionRequestModel.fromJson,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy ?? 'requested_at',
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (status != null && status != 'All') 'status': status,
      },
    );
  }

  Future<void> processRequest({
    required String id,
    required String newStatus,
    required String adminId,
  }) async {
    try {
      await _client.from('account_deletion_requests').update({
        'status': newStatus,
        'processed_by_admin_id': adminId,
        'processed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
