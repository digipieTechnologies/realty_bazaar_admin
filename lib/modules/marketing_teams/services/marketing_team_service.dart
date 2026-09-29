// File: lib/modules/marketing_teams/services/marketing_team_service.dart
// Purpose: Full-featured service for Super Admin Marketing Teams management, member assignments, and safe team deletion.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/base_supabase_service.dart';
import '../../../core/network/pagination_model.dart';
import '../../../models/models.dart';

class MarketingTeamsPaginatedResponse {
  final List<MarketingTeamModel> teams;
  final PaginationMetadata pagination;
  final Map<String, int> kpis;

  const MarketingTeamsPaginatedResponse({
    required this.teams,
    required this.pagination,
    required this.kpis,
  });
}

class AvailableMarketingUser {
  final UserModel user;
  final String? currentTeamId;
  final String? currentTeamName;

  const AvailableMarketingUser({
    required this.user,
    this.currentTeamId,
    this.currentTeamName,
  });

  bool get hasTeam => currentTeamId != null && currentTeamId!.isNotEmpty;
}

class MarketingTeamService extends BaseSupabaseService {
  final SupabaseClient _client;

  static final MarketingTeamService _instance = MarketingTeamService._internal();

  factory MarketingTeamService({SupabaseClient? client}) {
    if (client != null) return MarketingTeamService._internal(client: client);
    return _instance;
  }

  MarketingTeamService._internal({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch paginated teams with filters and global KPIs using the optimized RPC
  Future<MarketingTeamsPaginatedResponse> fetchTeamsPaginated({
    int page = 1,
    int pageSize = 10,
    String? search,
    bool? isActive,
    String? territory,
    bool? hasBrokers,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final res = await _client.rpc('fetch_admin_marketing_teams', params: {
        'p_page': page,
        'p_limit': pageSize,
        'p_search': search ?? '',
        'p_is_active': isActive,
        'p_territory': territory,
        'p_has_brokers': hasBrokers,
        'p_sort_by': sortBy ?? 'created_at',
        'p_ascending': sortOrder == 'asc',
      });

      if (res is! Map || res['success'] != true) {
        final errorMsg = res is Map ? res['message']?.toString() : 'Failed to fetch marketing teams';
        throw Exception(errorMsg ?? 'Failed to fetch marketing teams');
      }

      final teamsData = (res['data'] as List? ?? [])
          .map((item) => MarketingTeamModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final paginationData = res['pagination'] as Map<String, dynamic>? ?? {};
      final pagination = PaginationMetadata(
        page: paginationData['current_page'] as int? ?? page,
        pageSize: paginationData['limit'] as int? ?? pageSize,
        total: paginationData['total_items'] as int? ?? teamsData.length,
        totalPages: paginationData['total_pages'] as int? ?? 1,
      );

      final rawKpis = res['kpis'] as Map<String, dynamic>? ?? {};
      final kpis = <String, int>{
        'total_teams': int.tryParse(rawKpis['total_teams']?.toString() ?? '0') ?? 0,
        'active_teams': int.tryParse(rawKpis['active_teams']?.toString() ?? '0') ?? 0,
        'total_members': int.tryParse(rawKpis['total_members']?.toString() ?? '0') ?? 0,
        'assigned_brokers': int.tryParse(rawKpis['assigned_brokers']?.toString() ?? '0') ?? 0,
        'unassigned_brokers': int.tryParse(rawKpis['unassigned_brokers']?.toString() ?? '0') ?? 0,
      };

      return MarketingTeamsPaginatedResponse(
        teams: teamsData,
        pagination: pagination,
        kpis: kpis,
      );
    } catch (e) {
      throw handleException(e, 'Failed to fetch marketing teams');
    }
  }

  /// Fetch active marketing teams for dropdowns and selectors
  Future<List<MarketingTeamModel>> fetchActiveTeams() async {
    try {
      final response = await _client
          .from('marketing_teams')
          .select()
          .eq('is_active', true)
          .order('name');
      return (response as List)
          .map((e) => MarketingTeamModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw handleException(e, 'Failed to load marketing teams');
    }
  }

  /// Fetch a single marketing team by its ID
  Future<MarketingTeamModel?> fetchTeamById(String teamId) async {
    try {
      // Query single row directly with counts
      final row = await _client.from('marketing_teams').select().eq('id', teamId).maybeSingle();
      if (row == null) return null;

      final membersRes = await _client
          .from('marketing_team_members')
          .select('id')
          .eq('team_id', teamId);
      final membersCount = (membersRes as List).length;

      final brokersRes = await _client
          .from('brokers')
          .select('id')
          .eq('marketing_team_id', teamId)
          .eq('is_deleted', false);
      final brokersCount = (brokersRes as List).length;

      final leadRes = await _client
          .from('marketing_team_members')
          .select('users(*)')
          .eq('team_id', teamId)
          .eq('is_lead', true)
          .maybeSingle();

      UserModel? leadUser;
      if (leadRes != null && leadRes['users'] != null) {
        leadUser = UserModel.fromJson(Map<String, dynamic>.from(leadRes['users'] as Map));
      }

      return MarketingTeamModel.fromJson(row).copyWith(
        membersCount: membersCount,
        brokersCount: brokersCount,
        leadUser: leadUser,
      );
    } catch (e) {
      throw handleException(e, 'Failed to load team details');
    }
  }

  /// Create a new marketing team
  Future<MarketingTeamModel> createTeam({
    required String name,
    String? territory,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final payload = {
        'name': name.trim(),
        'territory': territory?.trim().isEmpty == true ? null : territory?.trim(),
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
        'is_active': isActive,
        'created_by': ?currentUserId,
      };

      final response = await _client.from('marketing_teams').insert(payload).select().single();
      return MarketingTeamModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Failed to create marketing team');
    }
  }

  /// Update an existing marketing team
  Future<MarketingTeamModel> updateTeam(MarketingTeamModel team) async {
    try {
      final payload = {
        'name': team.name.trim(),
        'territory': team.territory?.trim().isEmpty == true ? null : team.territory?.trim(),
        'description': team.description?.trim().isEmpty == true ? null : team.description?.trim(),
        'is_active': team.isActive,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from('marketing_teams')
          .update(payload)
          .eq('id', team.id)
          .select()
          .single();
      return MarketingTeamModel.fromJson(response);
    } catch (e) {
      throw handleException(e, 'Failed to update marketing team');
    }
  }

  /// Toggle team active status
  Future<void> toggleTeamStatus(String teamId, bool isActive) async {
    try {
      await _client.from('marketing_teams').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', teamId);
    } catch (e) {
      throw handleException(e, 'Failed to update team status');
    }
  }

  /// Delete a marketing team safely with broker reassignment or unassign
  Future<int> deleteTeam({
    required String teamId,
    String? reassignTeamId,
  }) async {
    try {
      final res = await _client.rpc('delete_marketing_team', params: {
        'p_team_id': teamId,
        'p_reassign_team_id': reassignTeamId,
      });

      if (res is Map && res['success'] == true) {
        return int.tryParse(res['affected_brokers']?.toString() ?? '0') ?? 0;
      }
      final msg = res is Map ? res['message']?.toString() : 'Failed to delete team';
      throw Exception(msg ?? 'Failed to delete team');
    } catch (e) {
      throw handleException(e, 'Failed to delete marketing team');
    }
  }

  /// Fetch team members with their user profile
  Future<List<TeamMemberModel>> fetchTeamMembers(String teamId) async {
    try {
      final response = await _client
          .from('marketing_team_members')
          .select('id, team_id, user_id, is_lead, created_at, user:users(*)')
          .eq('team_id', teamId)
          .order('is_lead', ascending: false);

      final list = response as List;
      return list.map((item) => TeamMemberModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      throw handleException(e, 'Failed to load team members');
    }
  }

  /// Add a user to a team or atomically transfer them if they belong to another team
  Future<String> addOrTransferMember({
    required String teamId,
    required String userId,
    bool isLead = false,
  }) async {
    try {
      final res = await _client.rpc('add_or_transfer_team_member', params: {
        'p_team_id': teamId,
        'p_user_id': userId,
        'p_is_lead': isLead,
      });

      if (res is Map && res['success'] == true) {
        return res['message']?.toString() ?? 'Member updated successfully.';
      }
      final msg = res is Map ? res['message']?.toString() : 'Failed to add member';
      throw Exception(msg ?? 'Failed to add member');
    } catch (e) {
      throw handleException(e, 'Failed to add team member');
    }
  }

  /// Remove a member from a team
  Future<void> removeMember({
    required String teamId,
    required String userId,
  }) async {
    try {
      await _client
          .from('marketing_team_members')
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);
    } catch (e) {
      throw handleException(e, 'Failed to remove team member');
    }
  }

  /// Toggle lead status for a member
  Future<void> setMemberLeadStatus({
    required String teamId,
    required String userId,
    required bool isLead,
  }) async {
    try {
      if (isLead) {
        // Clear existing lead first
        await _client
            .from('marketing_team_members')
            .update({'is_lead': false})
            .eq('team_id', teamId);
      }
      await _client
          .from('marketing_team_members')
          .update({'is_lead': isLead})
          .eq('team_id', teamId)
          .eq('user_id', userId);
    } catch (e) {
      throw handleException(e, 'Failed to update lead status');
    }
  }

  /// Fetch assigned brokers for a specific team
  Future<List<BrokerModel>> fetchAssignedBrokers(String teamId) async {
    try {
      final response = await _client
          .from('brokers')
          .select('*, marketing_team:marketing_teams(*)')
          .eq('marketing_team_id', teamId)
          .eq('is_deleted', false)
          .order('business_name');

      final brokersList = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final userIds = brokersList
          .map((b) => b['primary_marketing_user_id'])
          .whereType<String>()
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await _client
              .from('users')
              .select('*')
              .filter('id', 'in', userIds);

          final usersMap = {
            for (final u in usersResponse as List)
              u['id'] as String: UserModel.fromJson(Map<String, dynamic>.from(u as Map))
          };

          for (final b in brokersList) {
            final pId = b['primary_marketing_user_id'];
            if (pId != null && usersMap.containsKey(pId)) {
              b['primary_marketing_user'] = usersMap[pId];
            }
          }
        } catch (e) {
          debugPrint('[MarketingTeamService] Warning: failed to populate primary marketing users: $e');
        }
      }

      return brokersList
          .map((e) => BrokerModel.fromJson(e))
          .toList();
    } catch (e) {
      throw handleException(e, 'Failed to load assigned brokers');
    }
  }

  /// Fetch all active marketing users with their current team assignment status
  Future<List<AvailableMarketingUser>> fetchAvailableMarketingUsers() async {
    try {
      final response = await _client
          .from('users')
          .select('*, marketing_team_members(team_id, marketing_teams(id, name))')
          .eq('role', 'marketing')
          .eq('is_deleted', false)
          .order('name');

      final list = response as List;
      final results = <AvailableMarketingUser>[];

      for (final item in list) {
        final user = UserModel.fromJson(Map<String, dynamic>.from(item as Map));
        String? currentTeamId;
        String? currentTeamName;

        final membersList = item['marketing_team_members'] as List?;
        if (membersList != null && membersList.isNotEmpty) {
          final firstMembership = membersList.first as Map<String, dynamic>?;
          if (firstMembership != null) {
            currentTeamId = firstMembership['team_id'] as String?;
            final teamData = firstMembership['marketing_teams'] as Map<String, dynamic>?;
            if (teamData != null) {
              currentTeamName = teamData['name'] as String?;
            }
          }
        }

        results.add(AvailableMarketingUser(
          user: user,
          currentTeamId: currentTeamId,
          currentTeamName: currentTeamName,
        ));
      }

      return results;
    } catch (e) {
      throw handleException(e, 'Failed to load marketing users');
    }
  }

  /// Assign or unassign a broker to a marketing team
  Future<bool> assignBrokerToTeam({
    required String brokerId,
    String? teamId,
    String? primaryUserId,
    String? notes,
  }) async {
    try {
      final res = await _client.rpc(
        'assign_broker_to_team',
        params: {
          'p_broker_id': brokerId,
          'p_team_id': teamId,
          'p_primary_user_id': primaryUserId,
          'p_notes': notes,
        },
      );
      if (res is Map && res['success'] == true) {
        return true;
      }
      final msg = res is Map ? res['message']?.toString() : 'Failed to assign broker.';
      throw Exception(msg ?? 'Failed to assign broker');
    } catch (e) {
      throw handleException(e, 'Failed to assign broker');
    }
  }
}
