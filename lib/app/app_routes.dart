import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_bootstrap.dart';
import '../app/app_constants.dart';
import '../main.dart';
import '../models/models.dart';
import '../modules/auth/screens/admin_login_screen.dart';
import '../modules/brokers/screens/broker_detail_screen.dart';
import '../modules/brokers/screens/brokers_screen.dart';
import '../modules/dashboard/screens/admin_dashboard_screen.dart';
import '../modules/dashboard/screens/admin_shell_layout_screen.dart';
import '../modules/leads/screens/lead_detail_screen.dart';
import '../modules/leads/screens/leads_screen.dart';
import '../modules/profile/screens/admin_profile_screen.dart';
import '../modules/properties/screens/admin_properties_screen.dart';
import '../modules/properties/screens/property_detail_screen.dart';
import '../modules/settings/screens/admin_settings_screen.dart';
import '../modules/social_posts/screens/social_post_detail_screen.dart';
import '../modules/social_posts/screens/social_posts_screen.dart';
import '../modules/support/screens/admin_support_screen.dart';
import '../modules/users/screens/user_detail_screen.dart';
import '../modules/users/screens/users_screen.dart';
import '../modules/video_requests/screens/video_request_detail_screen.dart';
import '../modules/video_requests/screens/video_requests_screen.dart';

// ── Route name constants ──────────────────────────────────────────────────────
const String loginPath = 'login';
const String dashboardPath = 'dashboard';
const String usersPath = 'users';
const String userDetailPath = 'user_detail';
const String brokersPath = 'brokers';
const String brokerDetailPath = 'broker_detail';
const String propertiesPath = 'properties';
const String propertyDetailPath = 'property_detail';
const String socialAccountsPath = 'social_accounts';
const String socialLeadsPath = 'social_leads';
const String socialLeadsDetailPath = 'social_leads_detail';
const String socialPostsPath = 'social_posts';
const String socialPostsDetailPath = 'social_posts_detail';
const String reportsPath = 'reports';
const String activityLogsPath = 'activity_logs';
const String settingsPath = 'settings';
const String profilePath = 'profile';
const String videoRequestsPath = 'video_requests';
const String videoRequestDetailPath = 'video_request_detail';
const String supportPath = 'support';

class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static GlobalKey<NavigatorState> get _rootNavigator => rootNavigatorKey;
  static final GlobalKey<NavigatorState> _shellNavigator = GlobalKey<NavigatorState>(debugLabel: 'shell');

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String support = '/support';
  static const String users = '/users';
  static const String userDetail = '/users/detail/:id';
  static const String brokers = '/brokers';
  static const String brokerDetail = '/brokers/detail/:id';
  static const String properties = '/properties';
  static const String propertyDetail = '/properties/detail/:id';
  static const String socialAccounts = '/social-accounts';
  static const String socialLeads = '/social-leads';
  static const String socialLeadsDetail = '/social-leads/detail/:id';
  static const String socialPosts = '/social-posts';
  static const String socialPostsDetail = '/social-posts/detail/:id';
  static const String reports = '/reports';
  static const String activityLogs = '/activity-logs';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String videoRequests = '/video-requests';
  static const String videoRequestDetail = '/video-requests/detail/:id';

  /// Storage key for preserving deep link URL across auth flows
  static const String pendingRedirectKey = AppConstants.pendingRedirectKey;

  // --- Helper Methods for Parameterized Paths ---
  static String userDetailPathHelper(String id) => '/users/detail/$id';
  static String brokerDetailPathHelper(String id) => '/brokers/detail/$id';
  static String propertyDetailPathHelper(String id) => '/properties/detail/$id';
  static String socialLeadDetailPath(String id) => '/social-leads/detail/$id';
  static String socialPostDetailPath(String id) => '/social-posts/detail/$id';
  static String videoRequestDetailPathHelper(String id) => '/video-requests/detail/$id';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigator,
    initialLocation: dashboard,
    debugLogDiagnostics: true,
    extraCodec: const _ExtraCodec(),
    redirect: (context, state) {
      final userId = sharedPrefs.getString(AppConstants.sessionKey);
      final isLoggedIn = userId != null && userId.isNotEmpty;
      final goingToLogin = state.matchedLocation == login;

      if (!isLoggedIn && !goingToLogin) {
        // Save the intended destination URL so user returns here after login
        final targetUri = state.uri.toString();
        if (targetUri.isNotEmpty && targetUri != '/' && targetUri != login) {
          sharedPrefs.setString(pendingRedirectKey, targetUri);
        }
        return login;
      }
      if (isLoggedIn && goingToLogin) {
        // Consume pending redirect URL stored from notification cold launch
        final pendingUrl = sharedPrefs.getString(pendingRedirectKey);
        if (pendingUrl != null && pendingUrl.isNotEmpty && pendingUrl != login && pendingUrl != '/') {
          sharedPrefs.remove(pendingRedirectKey);
          return pendingUrl;
        }
        return dashboard;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}', style: const TextStyle(color: Colors.red, fontSize: 16)),
      ),
    ),
    routes: <RouteBase>[
      // ── Public Auth Routes ────────────────────────────────────────────────
      GoRoute(
        name: loginPath,
        path: login,
        parentNavigatorKey: _rootNavigator,
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ── Authenticated Shell Routes ──────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigator,
        builder: (context, state, child) {
          return AppBootstrap(child: AdminShellLayoutScreen(child: child));
        },
        routes: [
          GoRoute(
            name: dashboardPath,
            path: dashboard,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminDashboardScreen()),
          ),
          GoRoute(
            name: usersPath,
            path: users,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const UsersScreen()),
            routes: [
              GoRoute(
                name: userDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final userId = state.pathParameters['id'];
                  final extra = state.extra;
                  final userModel = extra is UserModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? UserModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: UserDetailScreen(userId: userId, user: userModel),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: brokersPath,
            path: brokers,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const BrokersScreen()),
            routes: [
              GoRoute(
                name: brokerDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'];
                  final extra = state.extra;
                  final broker = extra is BrokerModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? BrokerModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: BrokerDetailScreen(brokerId: id, broker: broker),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: propertiesPath,
            path: properties,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminPropertiesScreen()),
            routes: [
              GoRoute(
                name: propertyDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'];
                  final extra = state.extra;
                  final property = extra is PropertyModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? PropertyModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: PropertyDetailScreen(propertyId: id, property: property),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: socialPostsPath,
            path: socialPosts,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SocialPostsScreen()),
            routes: [
              GoRoute(
                name: socialPostsDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final extra = state.extra;
                  final post = extra is SocialPostModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? SocialPostModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: SocialPostDetailScreen(postId: id, post: post),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: socialLeadsPath,
            path: socialLeads,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LeadsScreen()),
            routes: [
              GoRoute(
                name: socialLeadsDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'];
                  final extra = state.extra;
                  final lead = extra is SocialLeadModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? SocialLeadModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: LeadDetailScreen(leadId: id, lead: lead),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: settingsPath,
            path: settings,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminSettingsScreen()),
          ),
          GoRoute(
            name: profilePath,
            path: profile,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminProfileScreen()),
          ),
          GoRoute(
            name: videoRequestsPath,
            path: videoRequests,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const VideoRequestsScreen()),
            routes: [
              GoRoute(
                name: videoRequestDetailPath,
                path: 'detail/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'];
                  final extra = state.extra;
                  final request = extra is VideoRequestModel
                      ? extra
                      : extra is Map<String, dynamic>
                      ? VideoRequestModel.fromJson(extra)
                      : null;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: VideoRequestDetailScreen(requestId: id!),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: supportPath,
            path: support,
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AdminSupportScreen()),
          ),
        ],
      ),
    ],
  );
}

extension GoRouterLocation on GoRouter {
  String get location {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

extension GoRouterCustomExtension on GoRouter {
  void pushAndRemoveUntil(String path) async {
    while (canPop() == true) {
      pop();
    }
    pushReplacement(path);
  }
}

class _ExtraCodec extends Codec<Object?, Object?> {
  const _ExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _ExtraDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _ExtraEncoder();
}

class _ExtraEncoder extends Converter<Object?, Object?> {
  const _ExtraEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is UserModel) {
      return {'__type__': 'UserModel', 'data': input.toJson()};
    }
    if (input is BrokerModel) {
      return {'__type__': 'BrokerModel', 'data': input.toJson()};
    }
    if (input is PropertyModel) {
      return {'__type__': 'PropertyModel', 'data': input.toJson()};
    }
    if (input is VideoRequestModel) {
      return {'__type__': 'VideoRequestModel', 'data': input.toJson()};
    }
    if (input is SocialPostModel) {
      return {'__type__': 'SocialPostModel', 'data': input.toJson()};
    }
    if (input is SocialLeadModel) {
      return {'__type__': 'SocialLeadModel', 'data': input.toJson()};
    }
    return input;
  }
}

class _ExtraDecoder extends Converter<Object?, Object?> {
  const _ExtraDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<Object?, Object?>) {
      final map = Map<String, dynamic>.from(input);
      if (map.containsKey('__type__')) {
        final type = map['__type__'] as String;
        final data = map['data'] as Map<String, dynamic>;
        switch (type) {
          case 'UserModel':
            return UserModel.fromJson(data);
          case 'BrokerModel':
            return BrokerModel.fromJson(data);
          case 'PropertyModel':
            return PropertyModel.fromJson(data);
          case 'VideoRequestModel':
            return VideoRequestModel.fromJson(data);
          case 'SocialPostModel':
            return SocialPostModel.fromJson(data);
          case 'SocialLeadModel':
            return SocialLeadModel.fromJson(data);
        }
      }
    }
    return input;
  }
}
