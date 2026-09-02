import '../../../core/filters/base_filter_model.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';

class VideoRequestFilterModel extends BaseFilterModel {
  final String? search;
  final VideoRequestStatus? status;
  final VideoRequestApprovalStatus? adminApprovalStatus;

  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortOrder;

  const VideoRequestFilterModel({
    this.search,
    this.status,
    this.adminApprovalStatus,
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
        labelKey: 'notes',
        hintText: 'video_requests_search_notes_hint',
      ),
      FilterField(
        key: 'status',
        type: FilterType.singleSelect,
        labelKey: 'Workflow Status',
        staticOptions: VideoRequestStatus.values
            .where((s) => s != VideoRequestStatus.unknown)
            .map((s) => FilterOption(value: s.name, labelKey: s.displayName, isPlainLabel: true))
            .toList(),
      ),
      FilterField(
        key: 'adminApprovalStatus',
        type: FilterType.singleSelect,
        labelKey: 'Admin Approval Status',
        staticOptions: VideoRequestApprovalStatus.values
            .where((s) => s != VideoRequestApprovalStatus.unknown)
            .map((s) => FilterOption(value: s.name, labelKey: s.displayName, isPlainLabel: true))
            .toList(),
      ),
    ],
    defaultSortBy: 'created_at',
  );

  VideoRequestFilterModel copyWith({
    String? search,
    VideoRequestStatus? status,
    VideoRequestApprovalStatus? adminApprovalStatus,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearAdminApprovalStatus = false,
  }) {
    return VideoRequestFilterModel(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      adminApprovalStatus: clearAdminApprovalStatus
          ? null
          : (adminApprovalStatus ?? this.adminApprovalStatus),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  VideoRequestFilterModel reset() {
    return const VideoRequestFilterModel(page: 1, pageSize: 15, sortBy: 'created_at');
  }

  @override
  bool get hasActiveFilters => search != null || status != null || adminApprovalStatus != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'status': status?.name,
      'adminApprovalStatus': adminApprovalStatus?.name,
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  @override
  BaseFilterModel copyWithMap(Map<String, dynamic> map) {
    VideoRequestStatus? parsedStatus;
    if (map['status'] != null) {
      parsedStatus = VideoRequestStatus.values.firstWhere(
        (s) => s.name == map['status'] || s.apiValue == map['status'],
        orElse: () => VideoRequestStatus.unknown,
      );
      if (parsedStatus == VideoRequestStatus.unknown) parsedStatus = null;
    }

    VideoRequestApprovalStatus? parsedApproval;
    if (map['adminApprovalStatus'] != null) {
      parsedApproval = VideoRequestApprovalStatus.values.firstWhere(
        (a) => a.name == map['adminApprovalStatus'] || a.apiValue == map['adminApprovalStatus'],
        orElse: () => VideoRequestApprovalStatus.unknown,
      );
      if (parsedApproval == VideoRequestApprovalStatus.unknown) parsedApproval = null;
    }

    return VideoRequestFilterModel(
      search: map.containsKey('search') ? map['search'] as String? : search,
      status: map.containsKey('status') ? parsedStatus : status,
      adminApprovalStatus: map.containsKey('adminApprovalStatus') ? parsedApproval : adminApprovalStatus,
      page: map['page'] as int? ?? page,
      pageSize: map['pageSize'] as int? ?? pageSize,
      sortBy: map['sortBy'] as String? ?? sortBy,
      sortOrder: map['sortOrder'] as String? ?? sortOrder,
    );
  }

  @override
  List<Object?> get props => [search, status, adminApprovalStatus, page, pageSize, sortBy, sortOrder];
}
