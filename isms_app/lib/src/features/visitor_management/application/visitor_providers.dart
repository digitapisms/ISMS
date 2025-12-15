import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/visitor_repository.dart';
import '../domain/security_entry.dart';
import '../domain/visit.dart';
import '../domain/visitor.dart';

final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  final repo = VisitorRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

// Visitors
final visitorsProvider = FutureProvider<List<Visitor>>((ref) async {
  final repo = ref.read(visitorRepositoryProvider);
  return repo.fetchVisitors();
});

// Active visits (checked in)
final activeVisitsProvider = FutureProvider<List<Visit>>((ref) async {
  final repo = ref.read(visitorRepositoryProvider);
  return repo.fetchActiveVisits();
});

// All visits
final visitsProvider = FutureProvider<List<Visit>>((ref) async {
  final repo = ref.read(visitorRepositoryProvider);
  return repo.fetchVisits();
});

// Security entries
final securityEntriesProvider = FutureProvider<List<SecurityEntry>>((ref) async {
  final repo = ref.read(visitorRepositoryProvider);
  return repo.fetchSecurityEntries();
});

final activeSecurityEntriesProvider = FutureProvider<List<SecurityEntry>>((ref) async {
  final repo = ref.read(visitorRepositoryProvider);
  return repo.fetchActiveEntries();
});

