import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/social_posts/models/social_post_filter_model.dart';
import '../../modules/social_posts/services/social_post_service.dart';

class SocialPostsProvider extends ChangeNotifier {
  final SocialPostService _service = SocialPostService();

  List<SocialPostModel> _posts = [];
  PaginationMetadata? _pagination;
  SocialPostFilterModel _filter = const SocialPostFilterModel(page: 1, pageSize: 10, sortBy: 'created_at');
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<SocialPostModel> get posts => _posts;

  PaginationMetadata? get pagination => _pagination;

  SocialPostFilterModel get filter => _filter;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get currentPage => _filter.page;

  int get totalPages => _pagination?.totalPages ?? 1;

  int get totalCount => _pagination?.total ?? _posts.length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> fetchSocialPosts() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchSocialPosts(
        page: _filter.page,
        pageSize: _filter.pageSize,
        search: _filter.search,
        sortBy: _filter.sortBy,
        sortOrder: _filter.sortOrder,
        platform: _filter.platform,
        status: _filter.status,
      );

      _posts = response.items;
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

  Future<void> refresh() => fetchSocialPosts();

  void updateFilter(SocialPostFilterModel newFilter) {
    _filter = newFilter;
    fetchSocialPosts();
  }

  void setSearchQuery(String query) {
    _filter = _filter.copyWith(search: query.isEmpty ? null : query, page: 1);
    fetchSocialPosts();
  }

  void setPlatformFilter(String? platform) {
    _filter = _filter.copyWith(
      platform: platform == 'All' ? null : platform,
      clearPlatform: platform == 'All',
      page: 1,
    );
    fetchSocialPosts();
  }

  void setStatusFilter(String? status) {
    _filter = _filter.copyWith(
      status: status == 'All' ? null : status,
      clearStatus: status == 'All',
      page: 1,
    );
    fetchSocialPosts();
  }

  void setPage(int page) {
    _filter = _filter.copyWith(page: page);
    fetchSocialPosts();
  }

  Future<String?> createSocialPost({
    required String brokerId,
    required String propertyId,
    required String platform,
    required String caption,
    List<String> mediaUrls = const [],
    String status = 'published',
    DateTime? scheduledAt,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdId = await _service.createSocialPost(
        brokerId: brokerId,
        propertyId: propertyId,
        platform: platform,
        caption: caption,
        mediaUrls: mediaUrls,
        status: status,
        scheduledAt: scheduledAt,
      );
      _isLoading = false;
      await fetchSocialPosts();
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

  Future<bool> updateSocialPost(SocialPostModel post) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateSocialPost(post);

      final updatedModel = await _service.getSocialPostById(post.id!);
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        _posts[idx] = updatedModel;
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

  Future<bool> deleteSocialPost(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteSocialPost(id);
      _posts.removeWhere((p) => p.id == id);
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
