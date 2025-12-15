import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/core/network/supabase_client.dart';
import 'src/core/optimization/offline_manager.dart';
import 'src/features/backup_restore/services/scheduled_backup_service.dart';
import 'src/error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Error handling wrapper
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to console for web debugging
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    }
  };

  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) {
        debugPrint('✅ Environment variables loaded');
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Could not load .env file: $e');
      // Continue - some env vars might be set via system
    }

    // Initialize Hive
    try {
      await Hive.initFlutter();
      if (kDebugMode) {
        debugPrint('✅ Hive initialized');
      }
    } catch (e) {
      debugPrint('❌ Hive initialization failed: $e');
      // Continue - Hive is optional for some features
    }

    // Initialize Supabase
    try {
      await SupabaseManager.init();
      if (kDebugMode) {
        debugPrint('✅ Supabase initialized');
      }
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // Show error screen instead of white screen
      runApp(
        const ProviderScope(
          child: ErrorApp(message: 'Failed to connect to Supabase. Please check your configuration.'),
        ),
      );
      return;
    }

    // Initialize Offline Manager
    try {
      await OfflineManager.init();
      if (kDebugMode) {
        debugPrint('✅ Offline Manager initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Offline Manager initialization failed: $e');
      // Continue - offline features are optional
    }

    // Initialize Scheduled Backup Service
    try {
      await ScheduledBackupService.initialize();
      if (kDebugMode) {
        debugPrint('✅ Scheduled Backup Service initialized');
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Scheduled Backup Service initialization failed: $e');
      // Continue - scheduled backups are optional
    }

    // Run the app
    runApp(
      const ProviderScope(
        child: ISMSApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Catch any unexpected errors
    debugPrint('❌ Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error screen
    runApp(
      const ProviderScope(
        child: ErrorApp(message: 'Application failed to start. Please check the console for details.'),
      ),
    );
  }
}
