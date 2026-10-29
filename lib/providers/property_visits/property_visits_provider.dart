import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/property_visits/models/property_visit_filter_model.dart';
import '../../modules/property_visits/services/property_visit_service.dart';

class PropertyVisitsProvider extends ChangeNotifier {
  final PropertyVisitService _service;

  PropertyVisitsProvider({PropertyVisitService? service})
      : _service = service ?? PropertyVisitService();

  List<PropertyVisitModel> _visits = [];
  PaginationMetadata? _pagination;
  bool _isLoading = false;
  String? _error;
  PropertyVisitFilterModel _filter = const PropertyVisitFilterModel();

  List<PropertyVisitModel> get visits => _visits;
  PaginationMetadata? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PropertyVisitFilterModel get filter => _filter;

  int get currentPage => _pagination?.page ?? 1;
  int get totalPages => _pagination?.totalPages ?? 1;
  int get totalCount => _pagination?.total ?? _visits.length;

  Future<void> fetchVisits() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchVisits(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        status: _filter.status,
        brokerId: _filter.brokerId,
      );
      _visits = response.items;
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

  Future<void> refresh() => fetchVisits();

  void updateFilter(PropertyVisitFilterModel f) {
    _filter = f;
    fetchVisits();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchVisits();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(
      search: query.isEmpty ? null : query,
      clearSearch: query.isEmpty,
      page: 1,
    );
    fetchVisits();
  }

  Future<bool> updateVisitStatus(String id, String status, {String? notes}) async {
    try {
      await _service.updateVisitStatus(id, status, notes: notes);
      await fetchVisits();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
