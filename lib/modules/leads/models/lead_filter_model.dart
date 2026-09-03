import 'package:provider/provider.dart';

import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/lead_status_enum.dart';
import '../../../providers/leads/admin_leads_provider.dart';

class LeadFilterModel extends BaseFilterModel {
  final String? search;
  final String? platform;
  final String? brokerId;
  final LeadStatus? status;

  // Quick filters
  final bool? instagramOnly;
  final bool? facebookOnly;
  final bool? directOnly;
  final bool? activeOnly;
  final bool? inactiveOnly;
  final bool? junkOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const LeadFilterModel({
    this.search,
    this.platform,
    this.brokerId,
    this.status,
    this.instagramOnly,
    this.facebookOnly,
    this.directOnly,
    this.activeOnly,
    this.inactiveOnly,
    this.junkOnly,
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
        key: 'status',
        type: FilterType.singleSelect,
        labelKey: 'leads_status',
        staticOptions: [
          FilterOption(value: 'pending', labelKey: 'leads_status_pending'),
          FilterOption(value: 'active', labelKey: 'leads_status_active'),
          FilterOption(value: 'inactive', labelKey: 'leads_status_inactive'),
          FilterOption(value: 'converted', labelKey: 'leads_status_converted'),
          FilterOption(value: 'no_response', labelKey: 'leads_status_no_response'),
          FilterOption(value: 'junk', labelKey: 'leads_status_junk'),
        ],
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
        key: 'activeOnly',
        type: FilterType.quickFilter,
        labelKey: 'leads_status_active',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'inactiveOnly',
        type: FilterType.quickFilter,
        labelKey: 'leads_status_inactive',
        isQuickFilter: true,
      ),
      const FilterField(
        key: 'junkOnly',
        type: FilterType.quickFilter,
        labelKey: 'leads_status_junk',
        isQuickFilter: true,
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
    LeadStatus? status,
    bool? instagramOnly,
    bool? facebookOnly,
    bool? directOnly,
    bool? activeOnly,
    bool? inactiveOnly,
    bool? junkOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearPlatform = false,
    bool clearBrokerId = false,
    bool clearStatus = false,
    bool clearInstagramOnly = false,
    bool clearFacebookOnly = false,
    bool clearDirectOnly = false,
    bool clearActiveOnly = false,
    bool clearInactiveOnly = false,
    bool clearJunkOnly = false,
  }) {
    return LeadFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      platform: clearPlatform ? null : (platform ?? this.platform),
      brokerId: clearBrokerId ? null : (brokerId ?? this.brokerId),
      status: clearStatus ? null : (status ?? this.status),
      instagramOnly: clearInstagramOnly ? null : (instagramOnly ?? this.instagramOnly),
      facebookOnly: clearFacebookOnly ? null : (facebookOnly ?? this.facebookOnly),
      directOnly: clearDirectOnly ? null : (directOnly ?? this.directOnly),
      activeOnly: clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
      inactiveOnly: clearInactiveOnly ? null : (inactiveOnly ?? this.inactiveOnly),
      junkOnly: clearJunkOnly ? null : (junkOnly ?? this.junkOnly),
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
      status != null ||
      instagramOnly != null ||
      facebookOnly != null ||
      directOnly != null ||
      activeOnly != null ||
      inactiveOnly != null ||
      junkOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'platform': platform,
      'brokerId': brokerId,
      'status': status?.apiValue,
      'instagramOnly': instagramOnly,
      'facebookOnly': facebookOnly,
      'directOnly': directOnly,
      'activeOnly': activeOnly,
      'inactiveOnly': inactiveOnly,
      'junkOnly': junkOnly,
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
      status: map.containsKey('status')
          ? (map['status'] is LeadStatus
              ? map['status'] as LeadStatus?
              : (map['status'] != null ? LeadStatus.fromString(map['status'].toString()) : null))
          : status,
      instagramOnly: map.containsKey('instagramOnly') ? map['instagramOnly'] as bool? : instagramOnly,
      facebookOnly: map.containsKey('facebookOnly') ? map['facebookOnly'] as bool? : facebookOnly,
      directOnly: map.containsKey('directOnly') ? map['directOnly'] as bool? : directOnly,
      activeOnly: map.containsKey('activeOnly') ? map['activeOnly'] as bool? : activeOnly,
      inactiveOnly: map.containsKey('inactiveOnly') ? map['inactiveOnly'] as bool? : inactiveOnly,
      junkOnly: map.containsKey('junkOnly') ? map['junkOnly'] as bool? : junkOnly,
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
        status,
        instagramOnly,
        facebookOnly,
        directOnly,
        activeOnly,
        inactiveOnly,
        junkOnly,
        page,
        pageSize,
        sortBy,
        sortOrder,
      ];
}
