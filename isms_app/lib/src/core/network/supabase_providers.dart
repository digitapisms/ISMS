import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_client.dart';
import 'supabase_client.dart';

/// Exposes the initialized SupabaseClient for dependency injection.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseManager.client;
});

/// Provides a DatabaseClient abstraction for repositories.
final databaseClientProvider = Provider<DatabaseClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseDatabaseClient(client);
});

