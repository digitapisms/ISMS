import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/certificates_repository.dart';
import '../domain/certificate.dart';
import '../domain/certificate_template.dart';

final certificatesRepositoryProvider = Provider<CertificatesRepository>((ref) {
  final repo = CertificatesRepository();
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser?.schoolId != null) {
    repo.setSchoolId(currentUser!.schoolId);
  }
  return repo;
});

// Templates
final certificateTemplatesProvider = FutureProvider<List<CertificateTemplate>>((ref) async {
  final repo = ref.read(certificatesRepositoryProvider);
  return repo.fetchTemplates(isActive: true);
});

final allCertificateTemplatesProvider = FutureProvider<List<CertificateTemplate>>((ref) async {
  final repo = ref.read(certificatesRepositoryProvider);
  return repo.fetchTemplates();
});

// Certificates
final certificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  final repo = ref.read(certificatesRepositoryProvider);
  return repo.fetchCertificates();
});

final certificatesByRecipientProvider = FutureProvider.family<List<Certificate>, String>(
  (ref, recipientId) async {
    final repo = ref.read(certificatesRepositoryProvider);
    return repo.fetchCertificates(recipientId: recipientId);
  },
);

