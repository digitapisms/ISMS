import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:isms_app/src/core/storage/storage_providers.dart';
import 'package:isms_app/src/core/storage/storage_service.dart';
import 'package:isms_app/src/features/student_management/application/student_providers.dart';
import 'package:isms_app/src/features/student_management/data/student_repository.dart';
import 'package:isms_app/src/features/student_management/presentation/add_student_screen.dart';

class _MockStudentRepository extends Mock implements StudentRepository {}

class _MockStorageService extends Mock implements StorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddStudentScreen', () {
    late _MockStudentRepository studentRepository;
    late _MockStorageService storageService;

    setUp(() {
      studentRepository = _MockStudentRepository();
      storageService = _MockStorageService();

      when(() => studentRepository.fetchClasses())
          .thenAnswer((_) async => const []);
      when(() => studentRepository.fetchSections(any()))
          .thenAnswer((_) async => const []);
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentRepositoryProvider.overrideWithValue(studentRepository),
            storageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MaterialApp(
            home: AddStudentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapSave(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.save));
      await tester.pump();
    }

    testWidgets('shows validation errors when required fields are empty',
        (tester) async {
      await pumpScreen(tester);

      await tapSave(tester);

      expect(find.text('Required'), findsWidgets);
      verifyNever(() => studentRepository.createStudent(
            admissionNo: any(named: 'admissionNo'),
            fullName: any(named: 'fullName'),
            classId: any(named: 'classId'),
            sectionId: any(named: 'sectionId'),
            status: any(named: 'status'),
            dob: any(named: 'dob'),
            gender: any(named: 'gender'),
            bloodGroup: any(named: 'bloodGroup'),
            medicalInfo: any(named: 'medicalInfo'),
            avatarUrl: any(named: 'avatarUrl'),
          ));
    });

    testWidgets('submits form when required fields are provided', (tester) async {
      when(
        () => studentRepository.createStudent(
          admissionNo: any(named: 'admissionNo'),
          fullName: any(named: 'fullName'),
          classId: any(named: 'classId'),
          sectionId: any(named: 'sectionId'),
          status: any(named: 'status'),
          dob: any(named: 'dob'),
          gender: any(named: 'gender'),
          bloodGroup: any(named: 'bloodGroup'),
          medicalInfo: any(named: 'medicalInfo'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer((_) async => 'student-123');
      when(
        () => studentRepository.addEmergencyContact(
          studentId: any(named: 'studentId'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          relation: any(named: 'relation'),
        ),
      ).thenAnswer((_) async {});

      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Admission Number'),
        'ADM-1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Test Student',
      );
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact Name'),
        'Guardian',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number').last,
        '+123456789',
      );

      await tapSave(tester);
      await tester.pumpAndSettle();

      verify(
        () => studentRepository.createStudent(
          admissionNo: 'ADM-1',
          fullName: 'Test Student',
          classId: null,
          sectionId: null,
          status: 'active',
          dob: null,
          gender: null,
          bloodGroup: null,
          medicalInfo: null,
          avatarUrl: null,
        ),
      ).called(1);
      verify(
        () => studentRepository.addEmergencyContact(
          studentId: 'student-123',
          name: 'Guardian',
          phone: '+123456789',
          relation: 'Parent',
        ),
      ).called(1);
    });
  });
}

