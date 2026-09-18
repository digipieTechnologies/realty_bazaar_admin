import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/video_requests/models/video_request_filter_model.dart';
import '../../modules/video_requests/services/video_request_service.dart';

class VideoRequestsProvider extends ChangeNotifier {
  final VideoRequestService _service = VideoRequestService();

  List<VideoRequestModel> _requests = [];
  PaginationMetadata? _pagination;
  VideoRequestFilterModel _filter = const VideoRequestFilterModel(
    page: 1,
    pageSize: 10,
    sortBy: 'created_at',
  );
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<VideoRequestModel> get requests => _requests;

  PaginationMetadata? get pagination => _pagination;

  VideoRequestFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _requests.length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchVideoRequests() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? statusFilter;
      if (_filter.status != null && _filter.status != VideoRequestStatus.unknown) {
        statusFilter = _filter.status!.apiValue;
      }

      String? approvalFilter;
      if (_filter.adminApprovalStatus != null &&
          _filter.adminApprovalStatus != VideoRequestApprovalStatus.unknown) {
        approvalFilter = _filter.adminApprovalStatus!.apiValue;
      }

      final response = await _service.fetchVideoRequests(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        status: statusFilter,
        adminApprovalStatus: approvalFilter,
      );

      _requests = response.items;
      _pagination = response.pagination;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchVideoRequests();

  /// Fetch a single video request by ID directly from service
  Future<VideoRequestModel?> fetchRequestById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await _service.getVideoRequestById(id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFilter(VideoRequestFilterModel newFilter) {
    _filter = newFilter;
    fetchVideoRequests();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchVideoRequests();
  }

  void setStatusFilter(String? status) {
    VideoRequestStatus? parsedStatus;
    if (status != null && status != 'All' && status.isNotEmpty) {
      parsedStatus = VideoRequestStatus.values.firstWhere(
        (s) =>
            s.name.toLowerCase() == status.toLowerCase() ||
            s.displayName.toLowerCase() == status.toLowerCase(),
        orElse: () => VideoRequestStatus.unknown,
      );
      if (parsedStatus == VideoRequestStatus.unknown) parsedStatus = null;
    }
    _filter = _filter.copyWith(status: parsedStatus, clearStatus: parsedStatus == null, page: 1);
    fetchVideoRequests();
  }

  void setApprovalStatusFilter(String? approvalStatus) {
    VideoRequestApprovalStatus? parsedApproval;
    if (approvalStatus != null && approvalStatus != 'All' && approvalStatus.isNotEmpty) {
      parsedApproval = VideoRequestApprovalStatus.values.firstWhere(
        (a) =>
            a.name.toLowerCase() == approvalStatus.toLowerCase() ||
            a.displayName.toLowerCase() == approvalStatus.toLowerCase(),
        orElse: () => VideoRequestApprovalStatus.unknown,
      );
      if (parsedApproval == VideoRequestApprovalStatus.unknown) parsedApproval = null;
    }
    _filter = _filter.copyWith(
      adminApprovalStatus: parsedApproval,
      clearAdminApprovalStatus: parsedApproval == null,
      page: 1,
    );
    fetchVideoRequests();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchVideoRequests();
  }

  Future<String?> createVideoRequest({
    required String propertyId,
    required String brokerId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdId = await _service.createVideoRequest(
        propertyId: propertyId,
        brokerId: brokerId,
        notes: notes,
      );
      _isLoading = false;
      await fetchVideoRequests();
      return createdId;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateVideoRequest(VideoRequestModel request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateVideoRequest(request);

      final updatedModel = await _service.getVideoRequestById(request.id!);
      final idx = _requests.indexWhere((r) => r.id == request.id);
      if (idx != -1) {
        _requests[idx] = updatedModel;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVideoRequest(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteVideoRequest(id);
      _requests.removeWhere((r) => r.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveRequest(String id, {String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateApprovalStatus(
        id,
        adminApprovalStatus: VideoRequestApprovalStatus.approved.apiValue,
        status: VideoRequestStatus.assigned.apiValue,
        notes: notes,
      );

      final updatedModel = await _service.getVideoRequestById(id);
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _requests[idx] = updatedModel;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String id, {required String reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateApprovalStatus(
        id,
        adminApprovalStatus: VideoRequestApprovalStatus.rejected.apiValue,
        status: VideoRequestStatus.cancelled.apiValue,
        adminCancelReason: reason,
      );

      final updatedModel = await _service.getVideoRequestById(id);
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _requests[idx] = updatedModel;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
