import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/discipline_repository.dart';
import '../domain/discipline_action.dart';
import '../domain/discipline_incident.dart';

final disciplineRepositoryProvider = Provider<DisciplineRepository>((ref) {
  final repo = DisciplineRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

final disciplineIncidentsProvider = FutureProvider<List<DisciplineIncident>>((ref) async {
  final repo = ref.read(disciplineRepositoryProvider);
  return repo.fetchIncidents();
});

final disciplineActionsProvider = FutureProvider.family<List<DisciplineAction>, String?>((ref, incidentId) async {
  final repo = ref.read(disciplineRepositoryProvider);
  return repo.fetchActions(incidentId: incidentId);
});

