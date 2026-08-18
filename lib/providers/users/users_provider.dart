import 'package:brokerflow_admin/modules/users/models/user_filter_model.dart';
import 'package:brokerflow_admin/modules/users/services/user_service.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';

class UsersProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _users = [];
  PaginationMetadata? _pagination;
  UserFilterModel _filter = const UserFilterModel(page: 1, pageSize: 10, sortBy: 'created_at');
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<UserModel> get users => _users;

  PaginationMetadata? get pagination => _pagination;

  UserFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _users.length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchUsers() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? roleFilter;
      if (_filter.role != null && _filter.role != UserRole.unknown) {
        roleFilter = _filter.role!.apiValue;
      }

      final response = await _service.fetchUsers(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        role: roleFilter,
        isActive: _filter.isActive,
      );

      _users = response.items;
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

  Future<void> refresh() => fetchUsers();

  void updateFilter(UserFilterModel newFilter) {
    _filter = newFilter;
    fetchUsers();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchUsers();
  }

  void setRoleFilter(String? role) {
    UserRole? parsedRole;
    if (role != null && role != 'All' && role.isNotEmpty) {
      parsedRole = UserRole.values.firstWhere(
        (r) =>
            r.apiValue.toLowerCase() == role.toLowerCase() ||
            r.name.toLowerCase() == role.toLowerCase() ||
            r.displayName.toLowerCase() == role.toLowerCase(),
        orElse: () => UserRole.unknown,
      );
      if (parsedRole == UserRole.unknown) parsedRole = null;
    }
    _filter = _filter.copyWith(role: parsedRole, clearRole: parsedRole == null, page: 1);
    fetchUsers();
  }

  void setIsActiveFilter(bool? isActive) {
    _filter = _filter.copyWith(isActive: isActive, page: 1);
    fetchUsers();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchUsers();
  }

  Future<String?> createUser({
    required String name,
    required String email,
    String? phone,
    required UserRole role,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdId = await _service.createUser(
        name: name,
        email: email,
        phone: phone,
        role: role,
        isActive: isActive,
      );
      _isLoading = false;
      await fetchUsers();
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

  Future<bool> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateUser(updatedUser);

      final updatedModel = await _service.getUserById(id: updatedUser.id!);
      final idx = _users.indexWhere((u) => u.id == updatedUser.id);
      if (idx != -1) {
        _users[idx] = updatedModel;
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

  Future<bool> toggleUserStatus(String id) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return false;

    final current = _users[idx];
    final newStatus = !(current.isActive ?? true);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.toggleUserStatus(id, newStatus);
      _users[idx] = current.copyWith(isActive: newStatus);
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

  Future<bool> deleteUser(String id, {bool hardDelete = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteUser(userId: id, hardDelete: hardDelete);
      _users.removeWhere((u) => u.id == id);
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

  void updateLocalUser(UserModel user) {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _users[idx] = user;
      notifyListeners();
    }
  }
}
