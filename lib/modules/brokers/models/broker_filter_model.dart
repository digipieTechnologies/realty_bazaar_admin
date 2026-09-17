import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';

class BrokerFilterModel extends BaseFilterModel {
  final String? search;
  final String? plan;
  final String? onboardingStatus;
  final bool? isActive;
  final bool? enterpriseOnly;
  final bool? proOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const BrokerFilterModel({
    this.search,
    this.plan,
    this.onboardingStatus,
    this.isActive,
    this.enterpriseOnly,
    this.proOnly,
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
        labelKey: 'broker_search_label',
        hintText: 'broker_search_hint',
      ),
      const FilterField(
        key: 'plan',
        type: FilterType.singleSelect,
        labelKey: 'Subscription Plan',
        staticOptions: [
          FilterOption(value: 'Free', labelKey: 'Free Tier', isPlainLabel: true),
          FilterOption(value: 'Pro', labelKey: 'Pro Tier', isPlainLabel: true),
          FilterOption(value: 'Enterprise', labelKey: 'Enterprise Tier', isPlainLabel: true),
        ],
      ),
      const FilterField(
        key: 'onboardingStatus',
        type: FilterType.singleSelect,
        labelKey: 'Onboarding Status',
        staticOptions: [
          FilterOption(value: 'pending', labelKey: 'Pending Approval', isPlainLabel: true),
          FilterOption(value: 'completed', labelKey: 'Completed', isPlainLabel: true),
          FilterOption(value: 'rejected', labelKey: 'Rejected', isPlainLabel: true),
        ],
      ),
      const FilterField(
        key: 'enterpriseOnly',
        type: FilterType.quickFilter,
        labelKey: 'enterprise_only',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'proOnly',
        type: FilterType.quickFilter,
        labelKey: 'pro_only',
        isQuickFilter: true,
      ),
    ],
    defaultSortBy: 'created_at',
  );

  BrokerFilterModel copyWith({
    String? search,
    String? plan,
    String? onboardingStatus,
    bool? isActive,
    bool? enterpriseOnly,
    bool? proOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearPlan = false,
    bool clearOnboardingStatus = false,
    bool clearIsActive = false,
    bool clearEnterpriseOnly = false,
    bool clearProOnly = false,
  }) {
    return BrokerFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      plan: clearPlan ? null : (plan ?? this.plan),
      onboardingStatus: clearOnboardingStatus ? null : (onboardingStatus ?? this.onboardingStatus),
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      enterpriseOnly: clearEnterpriseOnly ? null : (enterpriseOnly ?? this.enterpriseOnly),
      proOnly: clearProOnly ? null : (proOnly ?? this.proOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  BrokerFilterModel reset() {
    return const BrokerFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters =>
      search != null ||
      plan != null ||
      onboardingStatus != null ||
      isActive != null ||
      enterpriseOnly != null ||
      proOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'plan': plan,
      'onboardingStatus': onboardingStatus,
      'isActive': isActive,
      'enterpriseOnly': enterpriseOnly,
      'proOnly': proOnly,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return BrokerFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      plan: map.containsKey('plan') ? map['plan'] as String? : plan,
      onboardingStatus: map.containsKey('onboardingStatus')
          ? map['onboardingStatus'] as String?
          : onboardingStatus,
      isActive: map.containsKey('isActive') ? map['isActive'] as bool? : isActive,
      enterpriseOnly: map.containsKey('enterpriseOnly') ? map['enterpriseOnly'] as bool? : enterpriseOnly,
      proOnly: map.containsKey('proOnly') ? map['proOnly'] as bool? : proOnly,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    search,
    plan,
    onboardingStatus,
    isActive,
    enterpriseOnly,
    proOnly,
    page,
    pageSize,
    sortBy,
    sortOrder,
  ];
}
