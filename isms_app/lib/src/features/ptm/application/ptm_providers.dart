import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/ptm_repository.dart';
import '../domain/ptm_meeting.dart';
import '../domain/ptm_note.dart';

final ptmRepositoryProvider = Provider<PTMRepository>((ref) {
  final repo = PTMRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

final ptmMeetingsProvider = FutureProvider<List<PTMMeeting>>((ref) async {
  final repo = ref.read(ptmRepositoryProvider);
  return repo.fetchMeetings();
});

final ptmNotesProvider = FutureProvider.family<List<PTMNote>, String>((ref, meetingId) async {
  final repo = ref.read(ptmRepositoryProvider);
  return repo.fetchNotes(meetingId);
});

