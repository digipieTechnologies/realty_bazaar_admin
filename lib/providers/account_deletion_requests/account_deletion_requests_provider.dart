import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/account_deletion_requests/services/account_deletion_request_service.dart';

class AccountDeletionRequestsProvider extends ChangeNotifier {
  final AccountDeletionRequestService _service;

  AccountDeletionRequestsProvider({AccountDeletionRequestService? service})
      : _service = service ?? AccountDeletionRequestService();

  List<AccountDeletionRequestModel> _requests = [];
  PaginationMetadata? _pagination;
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;

  List<AccountDeletionRequestModel> get requests => _requests;
  PaginationMetadata? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;

  int _page = 1;
  static const int _pageSize = 15;

  int get currentPage => _pagination?.page ?? 1;
  int get totalPages => _pagination?.totalPages ?? 1;
  int get totalCount => _pagination?.total ?? _requests.length;

  Future<void> fetchRequests() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchRequests(
        page: _page,
        pageSize: _pageSize,
        status: _statusFilter,
        sortBy: 'requested_at',
        sortOrder: 'desc',
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

  Future<void> refresh() => fetchRequests();

  void setStatusFilter(String? status) {
    _statusFilter = status == 'All' ? null : status;
    _page = 1;
    fetchRequests();
  }

  void setPage(int page) {
    _page = page;
    fetchRequests();
  }

  Future<bool> approveRequest(String id, String adminId) async {
    try {
      await _service.processRequest(id: id, newStatus: 'approved', adminId: adminId);
      await fetchRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String id, String adminId) async {
    try {
      await _service.processRequest(id: id, newStatus: 'rejected', adminId: adminId);
      await fetchRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
