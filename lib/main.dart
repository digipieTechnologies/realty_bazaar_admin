// File: lib/main.dart
// Purpose: Super Admin Application entry point, service initialization, and routing setup.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app/app_routes.dart';
import 'app/app_strings.dart';
import 'app/app_theme.dart';
import 'core/network/supabase_client.dart';
import 'providers/activity_logs/activity_logs_provider.dart';
import 'providers/auth/admin_auth_provider.dart';
import 'providers/brokers/brokers_provider.dart';
import 'providers/dashboard/admin_dashboard_provider.dart';
import 'providers/language/language_provider.dart';
import 'providers/leads/admin_leads_provider.dart';
import 'providers/properties/admin_property_provider.dart';
import 'providers/reports/reports_provider.dart';
import 'providers/social/admin_social_provider.dart';
import 'providers/social_posts/social_posts_provider.dart';
import 'providers/chat/admin_chat_provider.dart';
import 'providers/support/admin_support_provider.dart';
import 'providers/users/users_provider.dart';
import 'providers/video_requests/video_requests_provider.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Disable all easy_localization logs completely
  // EasyLocalization.logger.enableBuildModes = [];

  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase initialized successfully in Super Admin!');
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const SuperAdminApp(),
    ),
  );
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => BrokersProvider()),
        ChangeNotifierProvider(create: (_) => AdminPropertyProvider()),
        ChangeNotifierProvider(create: (_) => AdminSocialProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLogsProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VideoRequestsProvider()),
        ChangeNotifierProvider(create: (_) => SocialPostsProvider()),
        ChangeNotifierProvider(create: (_) => AdminLeadsProvider()),
        ChangeNotifierProvider(create: (_) => AdminSupportProvider()),
        ChangeNotifierProvider(create: (_) => AdminChatProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRoutes.router,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
