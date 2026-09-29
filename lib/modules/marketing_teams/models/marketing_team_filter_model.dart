// File: lib/modules/marketing_teams/models/marketing_team_filter_model.dart
// Purpose: Type-safe filter model and definition for Marketing Teams list screen.

import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';

class MarketingTeamFilterModel extends BaseFilterModel {
  final String? search;
  final String? territory;
  final bool? isActive;
  final bool? hasBrokersOnly;
  final bool? emptyTeamsOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const MarketingTeamFilterModel({
    this.search,
    this.territory,
    this.isActive,
    this.hasBrokersOnly,
    this.emptyTeamsOnly,
    this.page = 1,
    this.pageSize = 10,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  static final filterDefinition = FilterDefinition(
    fields: [
      const FilterField(
        key: 'search',
        type: FilterType.search,
        labelKey: 'Search Teams',
        hintText: 'Search by team name, territory, description...',
      ),
      const FilterField(
        key: 'hasBrokersOnly',
        type: FilterType.quickFilter,
        labelKey: 'has_assigned_brokers',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'emptyTeamsOnly',
        type: FilterType.quickFilter,
        labelKey: 'empty_teams_only',
        isQuickFilter: true,
      ),
    ],
    defaultSortBy: 'created_at',
  );

  MarketingTeamFilterModel copyWith({
    String? search,
    String? territory,
    bool? isActive,
    bool? hasBrokersOnly,
    bool? emptyTeamsOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearTerritory = false,
    bool clearIsActive = false,
    bool clearHasBrokersOnly = false,
    bool clearEmptyTeamsOnly = false,
  }) {
    return MarketingTeamFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      territory: clearTerritory ? null : (territory ?? this.territory),
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      hasBrokersOnly: clearHasBrokersOnly ? null : (hasBrokersOnly ?? this.hasBrokersOnly),
      emptyTeamsOnly: clearEmptyTeamsOnly ? null : (emptyTeamsOnly ?? this.emptyTeamsOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  MarketingTeamFilterModel reset() {
    return const MarketingTeamFilterModel(page: 1, pageSize: 10, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters =>
      search != null ||
      territory != null ||
      isActive != null ||
      hasBrokersOnly != null ||
      emptyTeamsOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'territory': territory,
      'isActive': isActive,
      'hasBrokersOnly': hasBrokersOnly,
      'emptyTeamsOnly': emptyTeamsOnly,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return MarketingTeamFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      territory: map.containsKey('territory') ? map['territory'] as String? : territory,
      isActive: map.containsKey('isActive') ? map['isActive'] as bool? : isActive,
      hasBrokersOnly:
          map.containsKey('hasBrokersOnly') ? map['hasBrokersOnly'] as bool? : hasBrokersOnly,
      emptyTeamsOnly:
          map.containsKey('emptyTeamsOnly') ? map['emptyTeamsOnly'] as bool? : emptyTeamsOnly,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        search,
        territory,
        isActive,
        hasBrokersOnly,
        emptyTeamsOnly,
        page,
        pageSize,
        sortBy,
        sortOrder,
      ];
}
