// File: lib/providers/social/admin_social_provider.dart
// Purpose: State management provider for Social Accounts, Social Leads, and Social Posts administration.

import 'package:flutter/material.dart';

import '../../core/services/admin_data_service.dart';
import '../../models/models.dart';

class AdminSocialProvider extends ChangeNotifier {
  List<SocialAccountModel> _accounts = [];
  List<SocialLeadModel> _leads = [];
  List<SocialPostModel> _posts = [];
  bool _isLoading = false;

  List<SocialAccountModel> get accounts => _accounts;

  List<SocialLeadModel> get leads => _leads;

  List<SocialPostModel> get posts => _posts;

  bool get isLoading => _isLoading;

  Future<void> fetchSocialData() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await AdminDataService.instance.getSocialAccounts();
    _leads = await AdminDataService.instance.getSocialLeads();
    _posts = await AdminDataService.instance.getSocialPosts();

    _isLoading = false;
    notifyListeners();
  }
}
