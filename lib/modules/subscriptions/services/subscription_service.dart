import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class SubscriptionService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService({SupabaseClient? client}) {
    if (client != null) return SubscriptionService._internal(client: client);
    return _instance;
  }

  SubscriptionService._internal({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<List<SubscriptionPlanModel>> fetchPlans() async {
    try {
      final response = await _client
          .from('subscription_plans')
          .select('*')
          .order('created_at', ascending: true);
      return (response as List).map((e) => SubscriptionPlanModel.fromJson(e)).toList();
    } catch (e) {
      throw handleException(e, 'Error fetching plans');
    }
  }

  Future<void> togglePlanActive(String planId, bool isActive) async {
    try {
      await _client.from('subscription_plans').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', planId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  Future<PaginatedResponse<UserSubscriptionModel>> fetchSubscriptions({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    String? brokerId,
  }) async {
    return getPaginated<UserSubscriptionModel>(
      table: 'user_subscriptions',
      select: '*, broker_id(*), subscription_plan_id(*)',
      fromJson: UserSubscriptionModel.fromJson,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy ?? 'created_at',
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (brokerId != null) 'broker_id': brokerId,
      },
    );
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<PaginatedResponse<UserPaymentModel>> fetchPayments({
    int? page,
    int? pageSize,
    String? status,
    String? sortBy,
    String? sortOrder,
    String? brokerId,
  }) async {
    return getPaginated<UserPaymentModel>(
      table: 'user_payments',
      select: '*, broker_id(*), subscription_plan_id(*)',
      fromJson: UserPaymentModel.fromJson,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy ?? 'created_at',
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        if (status != null && status != 'All') 'status': status,
        if (brokerId != null) 'broker_id': brokerId,
      },
    );
  }
}
