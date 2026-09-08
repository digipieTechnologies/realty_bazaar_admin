// File: lib/providers/leads/admin_leads_provider.dart
// Purpose: State management provider for Super Admin Social Leads administration.

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/broker_model.dart';
import '../../models/lead_status_enum.dart';
import '../../models/social_lead_model.dart';
import '../../modules/leads/models/lead_filter_model.dart';
import '../../modules/leads/services/lead_service.dart';

class AdminLeadsProvider extends ChangeNotifier {
  final LeadService _service = LeadService();

  List<SocialLeadModel> _leads = [];
  PaginationMetadata? _pagination;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchQuery = '';
  List<String> _platformsFilter = [];
  String? _selectedBrokerId;
  LeadStatus? _statusFilter;
  LeadFilterModel _filter = const LeadFilterModel();

  List<BrokerModel> _brokers = [];
  bool _isLoadingBrokers = false;

  SocialLeadModel? _selectedLead;
  bool _isLoadingDetail = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<SocialLeadModel> get leads => _leads;
  PaginationMetadata? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => _pagination?.totalPages ?? 1;
  int get totalItems => _pagination?.total ?? _leads.length;

  String get searchQuery => _searchQuery;
  List<String> get platformsFilter => _platformsFilter;
  String? get selectedBrokerId => _selectedBrokerId;

  List<BrokerModel> get brokers => _brokers;
  bool get isLoadingBrokers => _isLoadingBrokers;

  SocialLeadModel? get selectedLead => _selectedLead;
  bool get isLoadingDetail => _isLoadingDetail;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Fetches paginated social leads with search, platform filter, and broker filter.
  Future<void> fetchLeads({int? page, bool isSilent = false}) async {
    if (page != null) {
      _currentPage = page;
    }

    if (!isSilent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _service.fetchLeads(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
        platforms: _platformsFilter,
        brokerId: _selectedBrokerId,
        status: _statusFilter,
      );

      _leads = response.items;
      _pagination = response.pagination;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LeadFilterModel get filter => _filter;

  Future<void> refresh() => fetchLeads(page: _currentPage);

  void updateFilter(LeadFilterModel newFilter) {
    _filter = newFilter;
    _currentPage = newFilter.page;
    _searchQuery = newFilter.search ?? '';

    // Resolve platforms from singleSelect or quickFilters
    if (newFilter.instagramOnly == true) {
      _platformsFilter = ['instagram'];
    } else if (newFilter.facebookOnly == true) {
      _platformsFilter = ['facebook'];
    } else if (newFilter.directOnly == true) {
      _platformsFilter = ['other'];
    } else if (newFilter.platform != null && newFilter.platform!.isNotEmpty && newFilter.platform != 'all') {
      _platformsFilter = [newFilter.platform!];
    } else {
      _platformsFilter = [];
    }

    // Resolve status from quick filters or dropdown
    if (newFilter.activeOnly == true) {
      _statusFilter = LeadStatus.active;
    } else if (newFilter.inactiveOnly == true) {
      _statusFilter = LeadStatus.inactive;
    } else if (newFilter.junkOnly == true) {
      _statusFilter = LeadStatus.junk;
    } else {
      _statusFilter = newFilter.status;
    }

    _selectedBrokerId = (newFilter.brokerId == 'all' || newFilter.brokerId == '') ? null : newFilter.brokerId;
    fetchLeads();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _currentPage = 1;
    fetchLeads();
  }

  void setPlatformsFilter(List<String> platforms) {
    _platformsFilter = List<String>.from(platforms);
    _currentPage = 1;
    fetchLeads();
  }

  void setSelectedBrokerId(String? brokerId) {
    _selectedBrokerId = (brokerId == 'all' || brokerId == '') ? null : brokerId;
    _currentPage = 1;
    fetchLeads();
  }

  void setPage(int page) {
    if (_currentPage == page) return;
    _currentPage = page;
    fetchLeads();
  }

  /// Fetches brokers list for dropdown filtering & reassignment.
  Future<void> fetchBrokers() async {
    if (_brokers.isNotEmpty) return;
    _isLoadingBrokers = true;
    notifyListeners();

    try {
      _brokers = await _service.fetchBrokersForFilter();
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error fetching brokers: $e');
    } finally {
      _isLoadingBrokers = false;
      notifyListeners();
    }
  }

  /// Fetches single lead details for the detail screen.
  Future<SocialLeadModel?> fetchLeadById(String leadId) async {
    // 1. Check local list first
    for (final l in _leads) {
      if (l.id == leadId) {
        _selectedLead = l;
        notifyListeners();
        break;
      }
    }

    // 2. Fetch full relations from DB
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final fetched = await _service.fetchLeadById(leadId);
      if (fetched != null) {
        _selectedLead = fetched;
      }
      return fetched;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error fetching lead by id: $e');
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Creates a new lead and refreshes the current list.
  Future<SocialLeadModel?> createLead({
    required String userName,
    required String phone,
    required String propertyDetails,
    String? notes,
    String? brokerId,
    LeadStatus status = LeadStatus.pending,
  }) async {
    try {
      final newLead = await _service.createLead(
        userName: userName,
        phone: phone,
        propertyDetails: propertyDetails,
        notes: notes,
        brokerId: brokerId,
        status: status,
      );

      // Refresh list to show newly added lead
      await fetchLeads(page: 1);
      return newLead;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error creating lead: $e');
      rethrow;
    }
  }

  /// Updates an existing lead and updates local cache.
  Future<bool> updateLead(SocialLeadModel lead) async {
    try {
      await _service.updateLead(lead);

      final index = _leads.indexWhere((l) => l.id == lead.id);
      if (index != -1) {
        _leads[index] = lead;
      }
      if (_selectedLead?.id == lead.id) {
        _selectedLead = lead;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error updating lead: $e');
      return false;
    }
  }

  /// Updates lead status with optimistic local update and DB persistence.
  Future<bool> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    final oldIndex = _leads.indexWhere((l) => l.id == leadId);
    final oldLead = oldIndex != -1 ? _leads[oldIndex] : null;

    if (oldLead != null) {
      _leads[oldIndex] = oldLead.copyWith(status: newStatus);
    }
    if (_selectedLead?.id == leadId && _selectedLead != null) {
      _selectedLead = _selectedLead!.copyWith(status: newStatus);
    }
    notifyListeners();

    try {
      await _service.updateLeadStatus(leadId, newStatus);
      return true;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error updating lead status: $e');
      if (oldLead != null && oldIndex != -1) {
        _leads[oldIndex] = oldLead;
      }
      if (_selectedLead?.id == leadId && oldLead != null) {
        _selectedLead = oldLead;
      }
      notifyListeners();
      return false;
    }
  }

  /// Reassigns lead to a new broker and updates property details if provided.
  Future<bool> reassignBroker(String leadId, String? newBrokerId, {String? propertyDetails}) async {
    try {
      await _service.reassignBroker(leadId, newBrokerId, propertyDetails: propertyDetails);

      // Refetch detail if current
      if (_selectedLead?.id == leadId) {
        await fetchLeadById(leadId);
      }
      await fetchLeads(page: _currentPage, isSilent: true);
      return true;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error reassigning broker: $e');
      return false;
    }
  }

  /// Soft deletes a lead.
  Future<bool> deleteLead(String leadId) async {
    try {
      await _service.deleteLead(leadId);
      _leads.removeWhere((l) => l.id == leadId);
      if (_selectedLead?.id == leadId) {
        _selectedLead = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminLeadsProvider] Error deleting lead: $e');
      return false;
    }
  }
}
