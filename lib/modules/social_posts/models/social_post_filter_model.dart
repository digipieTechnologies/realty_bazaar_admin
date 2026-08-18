import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';

class SocialPostFilterModel extends BaseFilterModel {
  final String? search;
  final String? platform;
  final String? status;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const SocialPostFilterModel({
    this.search,
    this.platform,
    this.status,
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
        labelKey: 'Search Captions',
        hintText: 'Search by caption...',
      ),
      const FilterField(
        key: 'platform',
        type: FilterType.singleSelect,
        labelKey: 'Platform',
        staticOptions: [
          FilterOption(value: 'Instagram', labelKey: 'Instagram', isPlainLabel: true),
          FilterOption(value: 'Facebook', labelKey: 'Facebook', isPlainLabel: true),
          FilterOption(value: 'YouTube', labelKey: 'YouTube', isPlainLabel: true),
          FilterOption(value: 'TikTok', labelKey: 'TikTok', isPlainLabel: true),
        ],
      ),
      const FilterField(
        key: 'status',
        type: FilterType.singleSelect,
        labelKey: 'Post Status',
        staticOptions: [
          FilterOption(value: 'published', labelKey: 'Published', isPlainLabel: true),
          FilterOption(value: 'scheduled', labelKey: 'Scheduled', isPlainLabel: true),
          FilterOption(value: 'failed', labelKey: 'Failed', isPlainLabel: true),
        ],
      ),
    ],
    defaultSortBy: 'created_at',
  );

  SocialPostFilterModel copyWith({
    String? search,
    String? platform,
    String? status,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearPlatform = false,
    bool clearStatus = false,
  }) {
    return SocialPostFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      platform: clearPlatform ? null : (platform ?? this.platform),
      status: clearStatus ? null : (status ?? this.status),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  SocialPostFilterModel reset() {
    return const SocialPostFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters => search != null || platform != null || status != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'platform': platform,
      'status': status,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return SocialPostFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      platform: map.containsKey('platform') ? map['platform'] as String? : platform,
      status: map.containsKey('status') ? map['status'] as String? : status,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [search, platform, status, page, pageSize, sortBy, sortOrder];
}
