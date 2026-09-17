// File: lib/providers/auth/admin_auth_provider.dart
// Purpose: Super Admin Authentication provider with real Supabase Auth and database role verification.

import 'package:brokerflow_admin/models/models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_constants.dart';
import '../../core/supabase/supabase_config.dart';

class AdminAuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _adminUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  UserModel? get adminUser => _adminUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Super Admin Sign-In with live Supabase Auth API & strict database role verification
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        throw const AuthException('Please fill in all required fields.');
      }

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user returned.');
      }

      final profileResponse = await SupabaseConfig.client
          .from('users')
          .select('*, broker_id(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        await SupabaseConfig.client.auth.signOut();
        throw const AuthException('User profile not found in database registry.');
      }

      final userProfile = UserModel.fromJson(profileResponse);

      // Verify Super Admin / Admin role
      final role = userProfile.role.apiValue.toLowerCase();
      if (role != 'super_admin' && role != 'admin') {
        await SupabaseConfig.client.auth.signOut();
        throw const AuthException('Access Denied: Super Admin privileges required.');
      }

      if (userProfile.isDeleted ?? false) {
        await SupabaseConfig.client.auth.signOut();
        throw const AuthException('This account has been deleted.');
      }

      if (!(userProfile.isActive ?? true)) {
        await SupabaseConfig.client.auth.signOut();
        throw const AuthException('This account is currently deactivated.');
      }

      _adminUser = userProfile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.sessionKey, user.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Restore / refresh admin profile from active Supabase auth session
  Future<void> checkSessionStatus() async {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser != null) {
      try {
        final profileResponse = await SupabaseConfig.client
            .from('users')
            .select('*, broker_id(*)')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profileResponse != null) {
          _adminUser = UserModel.fromJson(profileResponse);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error restoring admin profile session: $e');
      }
    }
  }

  /// Sign out admin session
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.sessionKey);
      _adminUser = null;
      _setLoading(false);
    }
  }
}
