import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class UserService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final UserService _instance = UserService._internal();

  factory UserService({SupabaseClient? client}) {
    if (client != null) return UserService._internal(client: client);
    return _instance;
  }

  UserService._internal({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch list of all users with optional pagination, search, and role/active filters.
  Future<PaginatedResponse<UserModel>> fetchUsers({
    int? page,
    int? pageSize,
    String? search,
    String? sortBy,
    String? sortOrder,
    String? role,
    bool? isActive,
  }) async {
    return getPaginated<UserModel>(
      table: 'users',
      select: '*, broker_id(*)',
      fromJson: UserModel.fromJson,
      page: page,
      pageSize: pageSize,
      searchField: 'search_text',
      searchQuery: search,
      sortBy: sortBy,
      ascending: sortOrder?.toLowerCase() == 'asc',
      filters: {
        'is_deleted': false,
        if (isActive != null) 'is_active': isActive,
        if (role != null && role != 'All') 'role': role,
      },
    );
  }

  /// Create a new user account.
  Future<String> createUser({
    required String name,
    required String email,
    String? phone,
    String phoneCountryCode = '91',
    String phoneCountryIso = 'IN',
    required UserRole role,
    bool isActive = true,
  }) async {
    try {
      final existingEmail = await _client
          .from('users')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      if (existingEmail != null) {
        throw Exception('A user with this email address already exists.');
      }

      final response = await _client
          .from('users')
          .insert({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'phone': phone != null && phone.trim().isNotEmpty ? phone.trim() : null,
            'phone_country_code': phoneCountryCode,
            'phone_country_iso': phoneCountryIso,
            'role': role.apiValue,
            'is_active': isActive,
            'is_deleted': false,
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

  /// Update an existing user.
  Future<void> updateUser(UserModel user) async {
    if (user.id == null) throw Exception('User ID cannot be null for update.');
    try {
      if (user.email != null && user.email!.trim().isNotEmpty) {
        final existingEmail = await _client
            .from('users')
            .select('id')
            .eq('email', user.email!.trim().toLowerCase())
            .neq('id', user.id!)
            .maybeSingle();
        if (existingEmail != null) {
          throw Exception('A user with this email address already exists.');
        }
      }

      final payload = <String, dynamic>{
        if (user.name != null) 'name': user.name!.trim(),
        if (user.email != null) 'email': user.email!.trim().toLowerCase(),
        if (user.phone != null) 'phone': user.phone!.trim(),
        'phone_country_code': user.phoneCountryCode ?? '91',
        'phone_country_iso': user.phoneCountryIso ?? 'IN',
        'role': user.role.apiValue,
        if (user.isActive != null) 'is_active': user.isActive,
      };

      await _client.from('users').update(payload).eq('id', user.id!);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle active status of a user.
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _client.from('users').update({'is_active': isActive}).eq('id', userId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft-delete or hard-delete a user.
  Future<void> deleteUser({required String userId, bool hardDelete = false}) async {
    try {
      if (hardDelete) {
        await _client.from('users').delete().eq('id', userId);
      } else {
        await _client
            .from('users')
            .update({'is_deleted': true, 'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', userId);
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a user by ID.
  Future<UserModel> getUserById({required String id}) async {
    try {
      final response = await _client.from('users').select('*, broker_id(*)').eq('id', id).single();
      return UserModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Unexpected error fetching user');
    }
  }
}
