import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Hardcoded values for web deployment
  // These are embedded directly in the compiled code for reliability
  static const String _webSupabaseUrl =
      'https://kgyzawrrcksjbwfwadfi.supabase.co';
  static const String _webSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtneXphd3JyY2tzamJ3ZndhZGZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMDIzODcsImV4cCI6MjA3ODg3ODM4N30.vJ3yuO8BtxMkPePKR1ar2LqmaHKqKj9CpoacGN888gg';

  static String get url {
    if (kIsWeb) {
      // For web, use hardcoded value (embedded in compiled code)
      debugPrint('✅ Using embedded SUPABASE_URL for web');
      return _webSupabaseUrl;
    }
    // For local development or non-web platforms, use .env file
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get anonKey {
    if (kIsWeb) {
      // For web, use hardcoded value (embedded in compiled code)
      debugPrint('✅ Using embedded SUPABASE_ANON_KEY for web');
      return _webSupabaseAnonKey;
    }
    // For local development or non-web platforms, use .env file
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
}

class SupabaseManager {
  static Future<void> init() async {
    final url = SupabaseConfig.url;
    final anonKey = SupabaseConfig.anonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Supabase configuration is missing. Please check your .env file.\n'
        'Required: SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
    } catch (e) {
      throw Exception(
        'Failed to initialize Supabase: $e\n'
        'Please verify your Supabase URL and API key are correct.',
      );
    }
  }

  static SupabaseClient get client {
    if (!Supabase.instance.isInitialized) {
      throw Exception(
        'Supabase is not initialized. Call SupabaseManager.init() first.',
      );
    }
    return Supabase.instance.client;
  }
}
