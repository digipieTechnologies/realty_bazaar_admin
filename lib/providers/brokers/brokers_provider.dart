// File: lib/providers/brokers/brokers_provider.dart
// Purpose: State management provider for Brokers module matching UsersProvider architecture.

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/brokers/models/broker_filter_model.dart';
import '../../modules/brokers/services/broker_service.dart';

class BrokersProvider extends ChangeNotifier {
  final BrokerService _service = BrokerService();

  List<BrokerModel> _brokers = [];
  PaginationMetadata? _pagination;
  BrokerFilterModel _filter = const BrokerFilterModel(page: 1, pageSize: 10, sortBy: 'created_at');
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<BrokerModel> get brokers => _brokers;

  PaginationMetadata? get pagination => _pagination;

  BrokerFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _brokers.length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchBrokers() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? planFilter = _filter.plan;
      if (_filter.enterpriseOnly == true) {
        planFilter = 'Enterprise';
      } else if (_filter.proOnly == true) {
        planFilter = 'Pro';
      }

      final response = await _service.fetchBrokers(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        plan: planFilter,
        onboardingStatus: _filter.onboardingStatus,
        isActive: _filter.isActive,
      );

      _brokers = response.items;
      _pagination = response.pagination;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchBrokers();

  void updateFilter(BrokerFilterModel newFilter) {
    _filter = newFilter;
    fetchBrokers();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchBrokers();
  }

  void setPlanFilter(String? plan) {
    _filter = _filter.copyWith(plan: plan, clearPlan: plan == null, page: 1);
    fetchBrokers();
  }

  void setOnboardingStatusFilter(String? status) {
    _filter = _filter.copyWith(onboardingStatus: status, clearOnboardingStatus: status == null, page: 1);
    fetchBrokers();
  }

  void setIsActiveFilter(bool? isActive) {
    _filter = _filter.copyWith(isActive: isActive, page: 1);
    fetchBrokers();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchBrokers();
  }

  Future<String?> createBroker({
    required String businessName,
    String plan = 'Free',
    String onboardingStatus = 'pending',
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdId = await _service.createBroker(
        businessName: businessName,
        plan: plan,
        onboardingStatus: onboardingStatus,
        isActive: isActive,
      );
      _isLoading = false;
      await fetchBrokers();
      return createdId;
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

  Future<bool> updateBroker(BrokerModel updatedBroker) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateBroker(updatedBroker);

      final updatedModel = await _service.getBrokerById(id: updatedBroker.id!);
      final idx = _brokers.indexWhere((b) => b.id == updatedBroker.id);
      if (idx != -1) {
        _brokers[idx] = updatedModel;
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

  Future<bool> toggleBrokerStatus(String id) async {
    final idx = _brokers.indexWhere((b) => b.id == id);
    if (idx == -1) return false;

    final current = _brokers[idx];
    final newStatus = !(current.isActive ?? true);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.toggleBrokerStatus(id, newStatus);
      _brokers[idx] = current.copyWith(isActive: newStatus);
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

  Future<bool> deleteBroker(String id, {bool hardDelete = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteBroker(brokerId: id, hardDelete: hardDelete);
      _brokers.removeWhere((b) => b.id == id);
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

  void updateLocalBroker(BrokerModel broker) {
    final idx = _brokers.indexWhere((b) => b.id == broker.id);
    if (idx != -1) {
      _brokers[idx] = broker;
      notifyListeners();
    }
  }
}
