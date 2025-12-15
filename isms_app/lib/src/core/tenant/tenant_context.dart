import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/school_registration/domain/school.dart';

/// Tenant context provider - holds current school context
final tenantContextProvider = StateNotifierProvider<TenantContextNotifier, School?>((ref) {
  return TenantContextNotifier();
});

class TenantContextNotifier extends StateNotifier<School?> {
  TenantContextNotifier() : super(null);

  void setSchool(School? school) {
    state = school;
  }

  void clear() {
    state = null;
  }
}

/// Helper to get current school ID
String? getCurrentSchoolId(WidgetRef ref) {
  final school = ref.read(tenantContextProvider);
  return school?.id;
}

