import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_logger.dart';

class SupabaseConfig {
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String apiAuthToken = String.fromEnvironment('API_AUTH_TOKEN');

  static Future<void> initialize() async {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // httpClient: SupabaseLoggerClient(),
      );
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
