import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/property_enums.dart';

class PropertyFilterModel extends BaseFilterModel {
  final String? search;
  final String? status;
  final String? propertyType;
  final String? listingType;
  final String? constructionStatus;
  final String? furnishingStatus;
  final String? facing;
  final String? city;
  final double? priceMin;
  final double? priceMax;
  final double? areaMin;
  final double? areaMax;

  // Quick filters
  final bool? activeOnly;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const PropertyFilterModel({
    this.search,
    this.status,
    this.propertyType,
    this.listingType,
    this.constructionStatus,
    this.furnishingStatus,
    this.facing,
    this.city,
    this.priceMin,
    this.priceMax,
    this.areaMin,
    this.areaMax,
    this.activeOnly,
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
        labelKey: 'Search Properties',
        hintText: 'Search by title, type, location...',
      ),
      FilterField(
        key: 'status',
        type: FilterType.singleSelect,
        labelKey: 'Property Status',
        staticOptions: [
          PropertyStatus.available,
          PropertyStatus.sold,
          PropertyStatus.rented,
          PropertyStatus.underOffer,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      FilterField(
        key: 'propertyType',
        type: FilterType.singleSelect,
        labelKey: 'Property Type',
        staticOptions: [
          PropertyType.apartment,
          PropertyType.villa,
          PropertyType.rowHouse,
          PropertyType.penthouse,
          PropertyType.commercial,
          PropertyType.plot,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      FilterField(
        key: 'listingType',
        type: FilterType.singleSelect,
        labelKey: 'Listing Type',
        staticOptions: [
          ListingType.sale,
          ListingType.rent,
          ListingType.lease,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      const FilterField(
        key: 'price',
        type: FilterType.rangeSlider,
        labelKey: 'Price Range (₹)',
        min: 0,
        max: 50000000,
      ),
      FilterField(
        key: 'constructionStatus',
        type: FilterType.singleSelect,
        labelKey: 'Construction Status',
        isAdvanced: true,
        staticOptions: [
          ConstructionStatus.readyToMove,
          ConstructionStatus.underConstruction,
          ConstructionStatus.newLaunch,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      FilterField(
        key: 'furnishingStatus',
        type: FilterType.singleSelect,
        labelKey: 'Furnishing Status',
        isAdvanced: true,
        staticOptions: [
          FurnishingStatus.unfurnished,
          FurnishingStatus.semiFurnished,
          FurnishingStatus.fullyFurnished,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      FilterField(
        key: 'facing',
        type: FilterType.singleSelect,
        labelKey: 'Facing Direction',
        isAdvanced: true,
        staticOptions: [
          FacingDirection.east,
          FacingDirection.west,
          FacingDirection.north,
          FacingDirection.south,
          FacingDirection.northEast,
          FacingDirection.northWest,
          FacingDirection.southEast,
          FacingDirection.southWest,
        ].map((e) => FilterOption(value: e.apiValue, labelKey: e.displayName, isPlainLabel: true)).toList(),
      ),
      const FilterField(
        key: 'activeOnly',
        type: FilterType.quickFilter,
        labelKey: 'Active Only',
        isQuickFilter: true,
      ),
    ],
    defaultSortBy: 'created_at',
  );

  PropertyFilterModel copyWith({
    String? search,
    String? status,
    String? propertyType,
    String? listingType,
    String? constructionStatus,
    String? furnishingStatus,
    String? facing,
    String? city,
    double? priceMin,
    double? priceMax,
    double? areaMin,
    double? areaMax,
    bool? activeOnly,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearStatus = false,
    bool clearPropertyType = false,
    bool clearListingType = false,
    bool clearConstructionStatus = false,
    bool clearFurnishingStatus = false,
    bool clearFacing = false,
    bool clearActiveOnly = false,
  }) {
    return PropertyFilterModel(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      listingType: clearListingType ? null : (listingType ?? this.listingType),
      constructionStatus: clearConstructionStatus ? null : (constructionStatus ?? this.constructionStatus),
      furnishingStatus: clearFurnishingStatus ? null : (furnishingStatus ?? this.furnishingStatus),
      facing: clearFacing ? null : (facing ?? this.facing),
      city: city ?? this.city,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      areaMin: areaMin ?? this.areaMin,
      areaMax: areaMax ?? this.areaMax,
      activeOnly: clearActiveOnly ? null : (activeOnly ?? this.activeOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  PropertyFilterModel reset() {
    return const PropertyFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters =>
      search != null ||
      status != null ||
      propertyType != null ||
      listingType != null ||
      constructionStatus != null ||
      furnishingStatus != null ||
      facing != null ||
      city != null ||
      priceMin != null ||
      priceMax != null ||
      areaMin != null ||
      areaMax != null ||
      activeOnly != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'status': status,
      'propertyType': propertyType,
      'listingType': listingType,
      'constructionStatus': constructionStatus,
      'furnishingStatus': furnishingStatus,
      'facing': facing,
      'city': city,
      'priceMin': priceMin,
      'priceMax': priceMax,
      'areaMin': areaMin,
      'areaMax': areaMax,
      'activeOnly': activeOnly,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    return PropertyFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      status: map.containsKey('status') ? map['status'] as String? : status,
      propertyType: map.containsKey('propertyType') ? map['propertyType'] as String? : propertyType,
      listingType: map.containsKey('listingType') ? map['listingType'] as String? : listingType,
      constructionStatus: map.containsKey('constructionStatus')
          ? map['constructionStatus'] as String?
          : constructionStatus,
      furnishingStatus: map.containsKey('furnishingStatus')
          ? map['furnishingStatus'] as String?
          : furnishingStatus,
      facing: map.containsKey('facing') ? map['facing'] as String? : facing,
      city: map.containsKey('city') ? map['city'] as String? : city,
      priceMin: (map['priceMin'] as num?)?.toDouble() ?? priceMin,
      priceMax: (map['priceMax'] as num?)?.toDouble() ?? priceMax,
      areaMin: (map['areaMin'] as num?)?.toDouble() ?? areaMin,
      areaMax: (map['areaMax'] as num?)?.toDouble() ?? areaMax,
      activeOnly: map.containsKey('activeOnly') ? map['activeOnly'] as bool? : activeOnly,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    search,
    status,
    propertyType,
    listingType,
    constructionStatus,
    furnishingStatus,
    facing,
    city,
    priceMin,
    priceMax,
    areaMin,
    areaMax,
    activeOnly,
    page,
    pageSize,
    sortBy,
    sortOrder,
  ];
}
