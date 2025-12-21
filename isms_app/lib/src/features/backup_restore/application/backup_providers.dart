import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../data/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final repo = BackupRepository();
  final school = ref.read(currentSchoolProvider);
  repo.setSchoolId(school?.id);
  return repo;
});

