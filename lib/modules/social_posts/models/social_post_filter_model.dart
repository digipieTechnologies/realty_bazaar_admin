import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';

class SocialPostFilterModel extends BaseFilterModel {
  final String? search;
  final String? platform;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const SocialPostFilterModel({
    this.search,
    this.platform,
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
        labelKey: 'caption',
        hintText: 'social_posts_search_caption_hint',
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
    ],
    defaultSortBy: 'created_at',
  );

  SocialPostFilterModel copyWith({
    String? search,
    String? platform,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearPlatform = false,
  }) {
    return SocialPostFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      platform: clearPlatform ? null : (platform ?? this.platform),
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
  bool get hasActiveFilters => search != null || platform != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'platform': platform,
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
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [search, platform, page, pageSize, sortBy, sortOrder];
}
