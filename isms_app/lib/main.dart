import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/core/network/supabase_client.dart';
import 'src/core/optimization/offline_manager.dart';
import 'src/features/backup_restore/services/scheduled_backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await SupabaseManager.init();
  await OfflineManager.init();
  await ScheduledBackupService.initialize();

  runApp(
    const ProviderScope(
      child: ISMSApp(),
    ),
  );
}
