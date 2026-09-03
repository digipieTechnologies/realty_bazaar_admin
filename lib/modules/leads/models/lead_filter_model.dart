import 'package:provider/provider.dart';

import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';
import '../../../providers/leads/admin_leads_provider.dart';

class LeadFilterModel extends BaseFilterModel {
  final String? search;
  final String? platform;
  final String? brokerId;

  // Quick filters
  final bool? instagramOnly;
  final bool? facebookOnly;
  final bool? directOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const LeadFilterModel({
    this.search,
    this.platform,
    this.brokerId,
    this.instagramOnly,
    this.facebookOnly,
    this.directOnly,
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
        labelKey: 'search',
        hintText: 'leads_search_hint',
      ),
      const FilterField(
        key: 'platform',
        type: FilterType.singleSelect,
        labelKey: 'leads_filter_platform',
        staticOptions: [
          FilterOption(value: 'instagram', labelKey: 'Instagram', isPlainLabel: true),
          FilterOption(value: 'facebook', labelKey: 'Facebook', isPlainLabel: true),
          FilterOption(value: 'other', labelKey: 'Direct / Other', isPlainLabel: true),
        ],
      ),
      FilterField(
        key: 'brokerId',
        type: FilterType.singleSelect,
        labelKey: 'leads_filter_broker',
        dynamicOptionsResolver: (context) async {
          final prov = context.read<AdminLeadsProvider>();
          if (prov.brokers.isEmpty) {
            await prov.fetchBrokers();
          }
          return prov.brokers
              .map(
                (b) => FilterOption(
                  value: b.id,
                  labelKey: b.businessName?.isNotEmpty == true
                      ? b.businessName!
                      : 'Broker #${b.id?.substring(0, 6)}',
                  isPlainLabel: true,
                ),
              )
              .toList();
        },
      ),
      const FilterField(
        key: 'instagramOnly',
        type: FilterType.quickFilter,
        labelKey: 'instagram',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'facebookOnly',
        type: FilterType.quickFilter,
        labelKey: 'facebook',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'directOnly',
        type: FilterType.quickFilter,
        labelKey: 'direct',
        isQuickFilter: true,
      ),
    ],
    defaultSortBy: 'created_at',
  );

  LeadFilterModel copyWith({
    String? search,
    String? platform,
    String? brokerId,
    bool? instagramOnly,
    bool? facebookOnly,
    bool? directOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearPlatform = false,
    bool clearBrokerId = false,
    bool clearInstagramOnly = false,
    bool clearFacebookOnly = false,
    bool clearDirectOnly = false,
  }) {
    return LeadFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      platform: clearPlatform ? null : (platform ?? this.platform),
      brokerId: clearBrokerId ? null : (brokerId ?? this.brokerId),
      instagramOnly: clearInstagramOnly ? null : (instagramOnly ?? this.instagramOnly),
      facebookOnly: clearFacebookOnly ? null : (facebookOnly ?? this.facebookOnly),
      directOnly: clearDirectOnly ? null : (directOnly ?? this.directOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  LeadFilterModel reset() {
    return const LeadFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters =>
      search != null ||
      platform != null ||
      brokerId != null ||
      instagramOnly != null ||
      facebookOnly != null ||
      directOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'platform': platform,
      'brokerId': brokerId,
      'instagramOnly': instagramOnly,
      'facebookOnly': facebookOnly,
      'directOnly': directOnly,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return LeadFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      platform: map.containsKey('platform') ? map['platform'] as String? : platform,
      brokerId: map.containsKey('brokerId') ? map['brokerId'] as String? : brokerId,
      instagramOnly: map.containsKey('instagramOnly') ? map['instagramOnly'] as bool? : instagramOnly,
      facebookOnly: map.containsKey('facebookOnly') ? map['facebookOnly'] as bool? : facebookOnly,
      directOnly: map.containsKey('directOnly') ? map['directOnly'] as bool? : directOnly,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        search,
        platform,
        brokerId,
        instagramOnly,
        facebookOnly,
        directOnly,
        page,
        pageSize,
        sortBy,
        sortOrder,
      ];
}
