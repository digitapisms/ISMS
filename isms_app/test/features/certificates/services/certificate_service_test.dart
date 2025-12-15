import 'package:flutter_test/flutter_test.dart';
import 'package:isms_app/src/features/certificates/domain/certificate.dart';
import 'package:isms_app/src/features/certificates/domain/certificate_template.dart';
import 'package:isms_app/src/features/certificates/domain/certificate_type.dart';

void main() {
  group('Certificate Domain Models', () {
    test('Certificate model should have correct properties', () {
      final certificate = Certificate(
        id: 'test-id',
        schoolId: 'school-1',
        templateId: 'template-1',
        certificateNumber: 'CERT-001',
        certificateType: CertificateType.leaving,
        recipientType: RecipientType.student,
        recipientId: 'student-1',
        recipientName: 'John Doe',
        issuedDate: DateTime(2023, 1, 1),
        issuedBy: 'Principal',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      expect(certificate.id, 'test-id');
      expect(certificate.certificateNumber, 'CERT-001');
      expect(certificate.recipientName, 'John Doe');
    });

    test('CertificateTemplate model should have correct properties', () {
      final template = CertificateTemplate(
        id: 'template-1',
        schoolId: 'school-1',
        templateName: 'Test Template',
        certificateType: CertificateType.leaving,
        templateType: TemplateType.academic,
        templateContent: 'This is a test certificate for {name}',
        templateVariables: ['name'],
        isActive: true,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      expect(template.id, 'template-1');
      expect(template.templateName, 'Test Template');
      expect(template.templateVariables, contains('name'));
    });

    test('CertificateType enum should have correct values', () {
      expect(CertificateType.leaving.dbValue, 'leaving');
      expect(CertificateType.achievement.dbValue, 'achievement');
      expect(CertificateType.participation.dbValue, 'participation');
    });

    test('RecipientType enum should have correct values', () {
      expect(RecipientType.student.dbValue, 'student');
      expect(RecipientType.staff.dbValue, 'staff');
    });
  });
}