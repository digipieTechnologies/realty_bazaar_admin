import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';

class PropertyVisitFilterModel extends BaseFilterModel {
  final String? search;
  final String? status;
  final String? brokerId;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const PropertyVisitFilterModel({
    this.search,
    this.status,
    this.brokerId,
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
        labelKey: 'client_name',
        hintText: 'Search by client name',
      ),
      const FilterField(
        key: 'status',
        type: FilterType.singleSelect,
        labelKey: 'Status',
        staticOptions: [
          FilterOption(value: 'pending', labelKey: 'Pending', isPlainLabel: true),
          FilterOption(value: 'confirmed', labelKey: 'Confirmed', isPlainLabel: true),
          FilterOption(value: 'completed', labelKey: 'Completed', isPlainLabel: true),
          FilterOption(value: 'cancelled', labelKey: 'Cancelled', isPlainLabel: true),
        ],
      ),
    ],
    defaultSortBy: 'created_at',
  );

  PropertyVisitFilterModel copyWith({
    String? search,
    String? status,
    String? brokerId,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearBrokerId = false,
  }) {
    return PropertyVisitFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      brokerId: clearBrokerId ? null : (brokerId ?? this.brokerId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  PropertyVisitFilterModel reset() =>
      const PropertyVisitFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');

  @override
  bool get hasActiveFilters => search != null || status != null || brokerId != null;

  @override
  Map<String, dynamic> toJson() => {
        'search': search,
        'status': status,
        'brokerId': brokerId,
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return PropertyVisitFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      status: map.containsKey('status') ? map['status'] as String? : status,
      brokerId: map.containsKey('brokerId') ? map['brokerId'] as String? : brokerId,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props =>
      [search, status, brokerId, page, pageSize, sortBy, sortOrder];
}
