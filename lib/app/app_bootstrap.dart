import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_constants.dart';
import '../app/app_routes.dart';
import '../main.dart';
import '../providers/auth/admin_auth_provider.dart';

class AppBootstrap extends StatefulWidget {
  final Widget child;

  const AppBootstrap({super.key, required this.child});

  static void reset() => AppBootstrapState.reset();

  @override
  State<AppBootstrap> createState() => AppBootstrapState();
}

class AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  bool _hasError = false;
  static bool _hasBootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runBootstrap());
  }

  Future<void> _runBootstrap() async {
    if (_hasBootstrapped && !_hasError) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    try {
      final authProvider = context.read<AdminAuthProvider>();
      await authProvider.checkSessionStatus();

      // Check for pending notification redirect after session restore
      _consumePendingRedirect();

      _hasBootstrapped = true;
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('AppBootstrap error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  /// Consumes any stored notification redirect URL from cold launch.
  void _consumePendingRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final pendingUrl = sharedPrefs.getString(AppConstants.pendingRedirectKey);
        if (pendingUrl != null && pendingUrl.isNotEmpty && pendingUrl != AppRoutes.login) {
          await sharedPrefs.remove(AppConstants.pendingRedirectKey);
          debugPrint('👉 [AppBootstrap] Consuming pending notification redirect: $pendingUrl');
          AppRoutes.router.push(pendingUrl);
        }
      } catch (e) {
        debugPrint('Error consuming pending redirect: $e');
      }
    });
  }

  static void reset() {
    _hasBootstrapped = false;
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('failed_to_initialize_app'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _runBootstrap();
              },
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Offstage(offstage: !_isInitialized || _hasError, child: widget.child),
        if (_hasError) _buildErrorScreen() else if (!_isInitialized) _buildLoadingScreen(),
      ],
    );
  }
}
