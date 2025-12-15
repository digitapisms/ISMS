import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final repo = DocumentsRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

final documentsProvider = FutureProvider<List<Document>>((ref) async {
  final repo = ref.read(documentsRepositoryProvider);
  return repo.fetchDocuments();
});

