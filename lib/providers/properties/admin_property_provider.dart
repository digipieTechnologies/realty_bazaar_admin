// File: lib/providers/properties/admin_property_provider.dart
// Purpose: State management provider for Properties administration with PropertyService.

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/properties/models/property_filter_model.dart';
import '../../modules/properties/services/property_service.dart';

class AdminPropertyProvider extends ChangeNotifier {
  final PropertyService _service = PropertyService();

  List<PropertyModel> _properties = [];
  PaginationMetadata? _pagination;
  PropertyFilterModel _filter = const PropertyFilterModel(page: 1, pageSize: 10, sortBy: 'created_at');
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<PropertyModel> get properties => _properties;

  PaginationMetadata? get pagination => _pagination;

  PropertyFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _properties.length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchProperties() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchProperties(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        propertyType: _filter.propertyType,
        listingType: _filter.listingType,
        propertyStatus: _filter.status,
        constructionStatus: _filter.constructionStatus,
        furnishingStatus: _filter.furnishingStatus,
        facing: _filter.facing,
        priceMin: _filter.priceMin,
        priceMax: _filter.priceMax,
        isActive: _filter.activeOnly,
      );

      _properties = response.items;
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

  Future<void> refresh() => fetchProperties();

  void updateFilter(PropertyFilterModel newFilter) {
    _filter = newFilter;
    fetchProperties();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchProperties();
  }

  void setPropertyTypeFilter(String? type) {
    _filter = _filter.copyWith(propertyType: type, clearPropertyType: type == null, page: 1);
    fetchProperties();
  }

  void setListingTypeFilter(String? listingType) {
    _filter = _filter.copyWith(listingType: listingType, clearListingType: listingType == null, page: 1);
    fetchProperties();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchProperties();
  }

  Future<bool> updateStatus(String id, PropertyStatus newStatus) async {
    final idx = _properties.indexWhere((p) => p.id == id);
    if (idx == -1) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updatePropertyStatus(id, newStatus);
      _properties[idx] = _properties[idx].copyWith(propertyStatus: newStatus);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProperty(String id, {bool hardDelete = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteProperty(id: id, hardDelete: hardDelete);
      _properties.removeWhere((p) => p.id == id);
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

  void updateLocalProperty(PropertyModel updated) {
    final idx = _properties.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _properties[idx] = updated;
      notifyListeners();
    }
  }

  Future<PropertyModel?> saveProperty(PropertyModel property, {bool isEdit = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _service.saveProperty(property, isEdit: isEdit);
      if (saved != null) {
        if (isEdit) {
          updateLocalProperty(saved);
        } else {
          _properties.insert(0, saved);
        }
      }
      await refresh();
      return saved;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProperty(PropertyModel updated) async {
    updateLocalProperty(updated);
    return true;
  }
}
