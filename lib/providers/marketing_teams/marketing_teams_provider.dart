// File: lib/providers/marketing_teams/marketing_teams_provider.dart
// Purpose: State management provider for Marketing Teams module matching BrokersProvider architecture.

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/marketing_teams/models/marketing_team_filter_model.dart';
import '../../modules/marketing_teams/services/marketing_team_service.dart';

class MarketingTeamsProvider extends ChangeNotifier {
  final MarketingTeamService _service = MarketingTeamService();

  List<MarketingTeamModel> _teams = [];
  PaginationMetadata? _pagination;
  MarketingTeamFilterModel _filter = const MarketingTeamFilterModel(
    page: 1,
    pageSize: 10,
    sortBy: 'created_at',
    sortOrder: 'desc',
  );
  bool _isLoading = false;
  String? _error;

  // KPI Counters
  int _totalTeams = 0;
  int _activeTeams = 0;
  int _totalMembers = 0;
  int _assignedBrokers = 0;
  int _unassignedBrokers = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<MarketingTeamModel> get teams => _teams;

  PaginationMetadata? get pagination => _pagination;

  MarketingTeamFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _teams.length;

  int get totalTeams => _totalTeams;

  int get activeTeams => _activeTeams;

  int get totalMembers => _totalMembers;

  int get assignedBrokers => _assignedBrokers;

  int get unassignedBrokers => _unassignedBrokers;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchTeams() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool? hasBrokersFilter;
      if (_filter.hasBrokersOnly == true) {
        hasBrokersFilter = true;
      } else if (_filter.emptyTeamsOnly == true) {
        hasBrokersFilter = false;
      }

      final response = await _service.fetchTeamsPaginated(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        isActive: _filter.isActive,
        territory: _filter.territory,
        hasBrokers: hasBrokersFilter,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
      );

      _teams = response.teams;
      _pagination = response.pagination;

      // Update KPIs
      _totalTeams = response.kpis['total_teams'] ?? 0;
      _activeTeams = response.kpis['active_teams'] ?? 0;
      _totalMembers = response.kpis['total_members'] ?? 0;
      _assignedBrokers = response.kpis['assigned_brokers'] ?? 0;
      _unassignedBrokers = response.kpis['unassigned_brokers'] ?? 0;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchTeams();

  void updateFilter(MarketingTeamFilterModel newFilter) {
    _filter = newFilter;
    fetchTeams();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchTeams();
  }

  void setTerritoryFilter(String? territory) {
    _filter = _filter.copyWith(
      territory: territory,
      clearTerritory: territory == null,
      page: 1,
    );
    fetchTeams();
  }

  void setIsActiveFilter(bool? isActive) {
    _filter = _filter.copyWith(
      isActive: isActive,
      clearIsActive: isActive == null,
      page: 1,
    );
    fetchTeams();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchTeams();
  }

  Future<MarketingTeamModel?> createTeam({
    required String name,
    String? territory,
    String? description,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createTeam(
        name: name,
        territory: territory,
        description: description,
        isActive: isActive,
      );
      _isLoading = false;
      await fetchTeams();
      return created;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTeam(MarketingTeamModel updatedTeam) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _service.updateTeam(updatedTeam);
      final idx = _teams.indexWhere((t) => t.id == updatedTeam.id);
      if (idx != -1) {
        _teams[idx] = _teams[idx].copyWith(
          name: saved.name,
          territory: saved.territory,
          description: saved.description,
          isActive: saved.isActive,
          updatedAt: saved.updatedAt,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTeamStatus(String id) async {
    final idx = _teams.indexWhere((t) => t.id == id);
    if (idx == -1) return false;

    final current = _teams[idx];
    final newStatus = !current.isActive;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.toggleTeamStatus(id, newStatus);
      _teams[idx] = current.copyWith(isActive: newStatus);
      if (newStatus) {
        _activeTeams++;
      } else {
        _activeTeams = (_activeTeams - 1).clamp(0, _totalTeams);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTeam({
    required String teamId,
    String? reassignTeamId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteTeam(teamId: teamId, reassignTeamId: reassignTeamId);
      _isLoading = false;
      await fetchTeams();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
