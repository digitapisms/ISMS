/// School context initializer
///
/// Ensures school context is loaded immediately when user logs in
/// This prevents infinite loading by making school available synchronously

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/application/auth_providers.dart';
import '../../features/school_registration/domain/school.dart';
import 'school_context_provider.dart';
import 'tenant_context.dart';

/// Initialize school context when auth state changes
/// This provider watches auth state and loads school immediately
/// NOTE: This provider should NOT watch schoolContextLoaderProvider to avoid circular dependencies
final schoolContextInitializerProvider = Provider<void>((ref) {
  final authUser = ref.watch(authStateProvider);

  // When auth user changes, trigger school loading
  if (authUser != null) {
    // Trigger the loader - it will set tenantContextProvider when done
    // Don't watch it, just read it to trigger the load
    ref
        .read(schoolContextLoaderProvider.future)
        .then((school) {
          // School is already set by schoolContextLoaderProvider, no need to set again
        })
        .catchError((e) {
          // Error already logged in schoolContextLoaderProvider
        });
  } else {
    // Clear when user logs out
    ref.read(tenantContextProvider.notifier).clear();
  }
});
