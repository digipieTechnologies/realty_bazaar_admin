import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';

class UserFilterModel extends BaseFilterModel {
  final String? search;
  final UserRole? role;
  final bool? isActive;
  final bool? superAdminOnly;
  final bool? brokersOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const UserFilterModel({
    this.search,
    this.role,
    this.isActive,
    this.superAdminOnly,
    this.brokersOnly,
    this.page = 1,
    this.pageSize = 15,
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  static final filterDefinition = FilterDefinition(
    fields: [
      const FilterField(
        key: 'search',
        type: FilterType.search,
        labelKey: 'Search Users',
        hintText: 'Search by name or email...',
      ),
      FilterField(
        key: 'role',
        type: FilterType.singleSelect,
        labelKey: 'User Role',
        staticOptions: UserRole.values
            .where((r) => r != UserRole.unknown)
            .map((r) => FilterOption(value: r.name, labelKey: r.displayName, isPlainLabel: true))
            .toList(),
      ),
      const FilterField(
        key: 'superAdminOnly',
        type: FilterType.quickFilter,
        labelKey: 'Super Admins',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'brokersOnly',
        type: FilterType.quickFilter,
        labelKey: 'Brokers',
        isQuickFilter: true,
      ),
    ],
    defaultSortBy: 'created_at',
  );

  UserFilterModel copyWith({
    String? search,
    UserRole? role,
    bool? isActive,
    bool? superAdminOnly,
    bool? brokersOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearRole = false,
    bool clearIsActive = false,
    bool clearSuperAdminOnly = false,
    bool clearBrokersOnly = false,
  }) {
    return UserFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      role: clearRole ? null : (role ?? this.role),
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      superAdminOnly: clearSuperAdminOnly ? null : (superAdminOnly ?? this.superAdminOnly),
      brokersOnly: clearBrokersOnly ? null : (brokersOnly ?? this.brokersOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  UserFilterModel reset() {
    return const UserFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters =>
      search != null || role != null || isActive != null || superAdminOnly != null || brokersOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'role': role?.name,
      'isActive': isActive,
      'superAdminOnly': superAdminOnly,
      'brokersOnly': brokersOnly,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    UserRole? parsedRole;
    if (map['role'] != null) {
      parsedRole = UserRole.values.firstWhere(
        (r) => r.name == map['role'] || r.apiValue == map['role'],
        orElse: () => UserRole.unknown,
      );
    }

    return UserFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      role: map.containsKey('role') ? parsedRole : role,
      isActive: map.containsKey('isActive') ? map['isActive'] as bool? : isActive,
      superAdminOnly: map.containsKey('superAdminOnly') ? map['superAdminOnly'] as bool? : superAdminOnly,
      brokersOnly: map.containsKey('brokersOnly') ? map['brokersOnly'] as bool? : brokersOnly,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    search,
    role,
    isActive,
    superAdminOnly,
    brokersOnly,
    page,
    pageSize,
    sortBy,
    sortOrder,
  ];
}
