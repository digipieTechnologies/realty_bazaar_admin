import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/pagination_model.dart';
import '../../models/models.dart';
import '../../modules/subscriptions/services/subscription_service.dart';

class SubscriptionsProvider extends ChangeNotifier {
  final SubscriptionService _service;

  SubscriptionsProvider({SubscriptionService? service})
      : _service = service ?? SubscriptionService();

  // ── Plans state ────────────────────────────────────────────────────────────
  List<SubscriptionPlanModel> _plans = [];
  bool _plansLoading = false;
  String? _plansError;

  List<SubscriptionPlanModel> get plans => _plans;
  bool get plansLoading => _plansLoading;
  String? get plansError => _plansError;

  // ── Subscriptions state ────────────────────────────────────────────────────
  List<UserSubscriptionModel> _subscriptions = [];
  PaginationMetadata? _subsPagination;
  bool _subsLoading = false;
  String? _subsError;
  int _subsPage = 1;

  List<UserSubscriptionModel> get subscriptions => _subscriptions;
  PaginationMetadata? get subsPagination => _subsPagination;
  bool get subsLoading => _subsLoading;
  String? get subsError => _subsError;
  int get subsCurrentPage => _subsPagination?.page ?? 1;
  int get subsTotalPages => _subsPagination?.totalPages ?? 1;
  int get subsTotalCount => _subsPagination?.total ?? _subscriptions.length;

  // ── Payments state ─────────────────────────────────────────────────────────
  List<UserPaymentModel> _payments = [];
  PaginationMetadata? _paysPagination;
  bool _paysLoading = false;
  String? _paysError;
  int _paysPage = 1;
  String? _paysStatusFilter;

  List<UserPaymentModel> get payments => _payments;
  PaginationMetadata? get paysPagination => _paysPagination;
  bool get paysLoading => _paysLoading;
  String? get paysError => _paysError;
  String? get paysStatusFilter => _paysStatusFilter;
  int get paysCurrentPage => _paysPagination?.page ?? 1;
  int get paysTotalPages => _paysPagination?.totalPages ?? 1;
  int get paysTotalCount => _paysPagination?.total ?? _payments.length;

  // ── Plans ──────────────────────────────────────────────────────────────────

  Future<void> fetchPlans() async {
    _plansLoading = true;
    _plansError = null;
    notifyListeners();
    try {
      _plans = await _service.fetchPlans();
    } on ApiException catch (e) {
      _plansError = e.message;
    } catch (e) {
      _plansError = e.toString();
    } finally {
      _plansLoading = false;
      notifyListeners();
    }
  }

  Future<bool> togglePlanActive(String planId, bool isActive) async {
    try {
      await _service.togglePlanActive(planId, isActive);
      await fetchPlans();
      return true;
    } catch (e) {
      _plansError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────

  Future<void> fetchSubscriptions() async {
    if (_subsLoading) return;
    _subsLoading = true;
    _subsError = null;
    notifyListeners();
    try {
      final r = await _service.fetchSubscriptions(page: _subsPage, pageSize: 15);
      _subscriptions = r.items;
      _subsPagination = r.pagination;
    } on ApiException catch (e) {
      _subsError = e.message;
    } catch (e) {
      _subsError = e.toString();
    } finally {
      _subsLoading = false;
      notifyListeners();
    }
  }

  void setSubsPage(int page) {
    _subsPage = page;
    fetchSubscriptions();
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  Future<void> fetchPayments() async {
    if (_paysLoading) return;
    _paysLoading = true;
    _paysError = null;
    notifyListeners();
    try {
      final r = await _service.fetchPayments(
        page: _paysPage,
        pageSize: 15,
        status: _paysStatusFilter,
      );
      _payments = r.items;
      _paysPagination = r.pagination;
    } on ApiException catch (e) {
      _paysError = e.message;
    } catch (e) {
      _paysError = e.toString();
    } finally {
      _paysLoading = false;
      notifyListeners();
    }
  }

  void setPaysStatusFilter(String? status) {
    _paysStatusFilter = status == 'All' ? null : status;
    _paysPage = 1;
    fetchPayments();
  }

  void setPaysPage(int page) {
    _paysPage = page;
    fetchPayments();
  }
}
