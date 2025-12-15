import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:isms_app/src/core/network/database_client.dart';
import 'package:isms_app/src/features/student_management/data/student_repository.dart';

class _MockDatabaseClient extends Mock implements DatabaseClient {}

class _MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class _MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  group('StudentRepository', () {
    late _MockDatabaseClient db;
    late StudentRepository repository;

    setUp(() {
      db = _MockDatabaseClient();
      repository = StudentRepository(client: db);
      repository.setSchoolId('school-1');
    });

    test('createStudent inserts base records and updates user profile', () async {
      when(() => db.insertReturningSingle('students', any())).thenAnswer(
        (_) async => {'id': 'student-123'},
      );
      when(() => db.insert('student_details', any()))
          .thenAnswer((_) async => {});
      when(() => db.upsert('user_profiles', any()))
          .thenAnswer((_) async => {});

      final result = await repository.createStudent(
        admissionNo: 'ADM-1',
        fullName: 'Test Student',
        status: 'active',
        avatarUrl: 'https://example.com/photo.png',
        userId: 'user-1',
      );

      expect(result, 'student-123');

      verify(
        () => db.insertReturningSingle('students', {
          'admission_no': 'ADM-1',
          'status': 'active',
          'school_id': 'school-1',
          'user_id': 'user-1',
        }),
      ).called(1);

      verify(
        () => db.insert('student_details', {
          'student_id': 'student-123',
          'school_id': 'school-1',
          'full_name': 'Test Student',
          'avatar_url': 'https://example.com/photo.png',
        }),
      ).called(1);

      verify(
        () => db.upsert('user_profiles', {
          'user_id': 'user-1',
          'avatar_url': 'https://example.com/photo.png',
        }),
      ).called(1);
    });

    test('updateStudent updates related tables with filters', () async {
      when(
        () => db.selectMaybeSingle(
          'students',
          columns: 'user_id',
          filters: {'id': 'student-123', 'school_id': 'school-1'},
        ),
      ).thenAnswer((_) async => {'user_id': 'user-1'});
      when(() => db.upsert('user_profiles', any()))
          .thenAnswer((_) async => {});
      when(
        () => db.selectMaybeSingle(
          'student_details',
          filters: {'student_id': 'student-123', 'school_id': 'school-1'},
        ),
      ).thenAnswer((_) async => {'student_id': 'student-123'});
      when(() => db.update('students', any(), any()))
          .thenAnswer((_) async => {});
      when(() => db.update('student_details', any(), any()))
          .thenAnswer((_) async => {});

      await repository.updateStudent(
        studentId: 'student-123',
        admissionNo: 'ADM-2',
        fullName: 'Updated Name',
        avatarUrl: 'https://example.com/new.png',
        status: 'inactive',
      );

      verify(
        () => db.update('students', {
          'admission_no': 'ADM-2',
          'status': 'inactive',
        }, {'id': 'student-123', 'school_id': 'school-1'}),
      ).called(1);

      verify(
        () => db.update('student_details', {
          'full_name': 'Updated Name',
          'avatar_url': 'https://example.com/new.png',
        }, {'student_id': 'student-123', 'school_id': 'school-1'}),
      ).called(1);
    });

    test('deleteStudent removes related rows', () async {
      when(() => db.delete(any(), any())).thenAnswer((_) async => {});

      await repository.deleteStudent('student-123');

      verify(
        () => db.delete('students', {'id': 'student-123', 'school_id': 'school-1'}),
      ).called(1);
    });

    test('uploadDocument uploads to storage and records metadata', () async {
      final storage = _MockSupabaseStorageClient();
      final bucket = _MockStorageFileApi();
      when(() => db.storage).thenReturn(storage);
      when(() => storage.from('student-documents')).thenReturn(bucket);
      when(() => bucket.uploadBinary(any(), any(),
              fileOptions: any(named: 'fileOptions')))
          .thenAnswer((_) async => 'student-123/Report/report.pdf');
      when(() => bucket.getPublicUrl(any()))
          .thenReturn('https://example.com/file.pdf');

      when(() => db.insert('student_documents', any()))
          .thenAnswer((_) async => {});

      final bytes = Uint8List.fromList([1, 2, 3]);
      final url = await repository.uploadDocument(
        studentId: 'student-123',
        documentType: 'Report',
        fileBytes: bytes,
        fileName: 'report.pdf',
        schoolId: 'school-1',
      );

      expect(url, 'https://example.com/file.pdf');

      verify(
        () => bucket.uploadBinary('student-123/Report/report.pdf', bytes,
            fileOptions: any(named: 'fileOptions')),
      ).called(1);

      verify(
        () => db.insert('student_documents', {
          'student_id': 'student-123',
          'document_type': 'Report',
          'file_url': 'https://example.com/file.pdf',
          'school_id': 'school-1',
        }),
      ).called(1);
    });
  });
}

