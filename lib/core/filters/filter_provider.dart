import 'dart:async';

import 'package:flutter/widgets.dart';

import 'base_filter_model.dart';
import 'filter_field.dart';

class FilterProvider<T extends BaseFilterModel> extends ChangeNotifier {
  static const int searchDebounceMs = 400;

  final FilterDefinition definition;

  T _activeFilters;
  T _draftFilters;

  final Map<String, List<FilterOption>> _resolvedOptions = {};
  bool _isLoadingOptions = false;

  final VoidCallback _onApplyCallback;
  Timer? _searchDebounce;

  FilterProvider({required this.definition, required T initialFilters, required VoidCallback onApply})
    : _activeFilters = initialFilters,
      _draftFilters = initialFilters,
      _onApplyCallback = onApply;

  // ── Getters ───────────────────────────────────────────────────────────────

  T get activeFilters => _activeFilters;

  T get draftFilters => _draftFilters;

  Map<String, List<FilterOption>> get resolvedOptions => _resolvedOptions;

  bool get isLoadingOptions => _isLoadingOptions;

  bool get hasChanges {
    return _activeFilters != _draftFilters;
  }

  int get activeFiltersCount {
    int count = 0;
    final map = _activeFilters.toJson();
    map.forEach((key, val) {
      if (key == 'page' || key == 'pageSize' || key == 'sortBy' || key == 'sortOrder' || key == 'search') {
        return;
      }
      if (val != null) {
        if (val is List) {
          if (val.isNotEmpty) count++;
        } else if (val is bool) {
          if (val == true) count++;
        } else {
          count++;
        }
      }
    });
    return count;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Load options dynamically for fields with resolvers.
  Future<void> loadDynamicOptions(BuildContext context) async {
    bool hasResolvers = definition.fields.any((f) => f.dynamicOptionsResolver != null);
    if (!hasResolvers || _isLoadingOptions) return;

    _isLoadingOptions = true;
    notifyListeners();

    try {
      for (final field in definition.fields) {
        if (field.dynamicOptionsResolver != null) {
          final options = await field.dynamicOptionsResolver!(context);
          _resolvedOptions[field.key] = options;
        }
      }
    } catch (e) {
      debugPrint("Error loading dynamic filter options: $e");
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  /// Update a specific filter key in the draft.
  void updateDraftValue(String key, dynamic value) {
    final currentMap = Map<String, dynamic>.from(_draftFilters.toJson());
    currentMap[key] = value;
    _draftFilters = _draftFilters.copyWithMap(currentMap) as T;
    notifyListeners();
  }

  /// Clear a specific key in the draft.
  void clearDraftValue(String key) {
    final currentMap = Map<String, dynamic>.from(_draftFilters.toJson());
    currentMap[key] = null;
    _draftFilters = _draftFilters.copyWithMap(currentMap) as T;
    notifyListeners();
  }

  /// Discard draft edits and restore to active filter state.
  void discardDraft() {
    _draftFilters = _activeFilters;
    notifyListeners();
  }

  /// Reset all filters to default state.
  void reset() {
    _draftFilters = _draftFilters.reset() as T;
    notifyListeners();
  }

  /// Apply draft filters to active filter state and trigger reload.
  void apply() {
    _activeFilters = _draftFilters;
    notifyListeners();
    _onApplyCallback();
  }

  /// Update active search query immediately with debounce.
  void updateSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: searchDebounceMs), () {
      final currentMap = Map<String, dynamic>.from(_activeFilters.toJson());
      if (query.trim().isEmpty) {
        currentMap['search'] = null;
      } else {
        currentMap['search'] = query.trim();
      }
      currentMap['page'] = 1; // Reset to page 1 on search
      _activeFilters = _activeFilters.copyWithMap(currentMap) as T;
      _draftFilters = _activeFilters;
      notifyListeners();
      _onApplyCallback();
    });
  }

  // ── Query Parameters Deep Linking ──────────────────────────────────────────

  /// Serializes active filter state to query parameters.
  Map<String, String> toQueryParameters() {
    final map = _activeFilters.toJson();
    final params = <String, String>{};
    map.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          if (value.isNotEmpty) {
            params[key] = value.join(',');
          }
        } else {
          params[key] = value.toString();
        }
      }
    });
    return params;
  }

  /// Initializes active and draft filters from query parameters.
  void initializeFromQuery(Map<String, String> params) {
    final map = <String, dynamic>{};

    // Default values first
    for (final field in definition.fields) {
      if (field.defaultValue != null) {
        map[field.key] = field.defaultValue;
      }
    }

    // Parse params
    params.forEach((key, value) {
      final field = definition.fields.firstWhere(
        (f) => f.key == key,
        orElse: () => FilterField(key: key, type: FilterType.search, labelKey: ''),
      );
      if (field.type == FilterType.multiSelect) {
        map[key] = value.split(',');
      } else if (field.type == FilterType.boolean) {
        map[key] = value == 'true';
      } else if (key == 'page' || key == 'pageSize') {
        map[key] = int.tryParse(value) ?? map[key];
      } else if (field.type == FilterType.numberRange || field.type == FilterType.priceRange) {
        final doubleVal = double.tryParse(value);
        if (doubleVal != null) map[key] = doubleVal;
      } else {
        map[key] = value;
      }
    });

    _activeFilters = _activeFilters.copyWithMap(map) as T;
    _draftFilters = _activeFilters;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
