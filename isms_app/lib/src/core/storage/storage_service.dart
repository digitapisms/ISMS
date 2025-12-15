import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

class StorageService {
  SupabaseClient get _client => SupabaseManager.client;

  /// Upload a file to Supabase Storage
  ///
  /// [bucket] - The storage bucket name (e.g., 'logos', 'documents')
  /// [filePath] - Local file path
  /// [fileName] - Name to save the file as (optional, uses original name if not provided)
  /// [folder] - Optional folder path within the bucket
  ///
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String bucket,
    required String filePath,
    String? fileName,
    String? folder,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final bytes = await file.readAsBytes();
      final name = fileName ?? file.path.split('/').last;
      final path = folder != null ? '$folder/$name' : name;

      // Upload file
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/octet-stream',
            ),
          );

      // Get public URL
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload file from bytes
  Future<String> uploadFileFromBytes({
    required String bucket,
    required List<int> bytes,
    required String fileName,
    String? folder,
    String? contentType,
  }) async {
    try {
      final path = folder != null ? '$folder/$fileName' : fileName;

      final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            uint8List,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType ?? 'application/octet-stream',
            ),
          );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload school logo
  Future<String> uploadSchoolLogo({
    required String schoolId,
    required String filePath,
  }) async {
    return uploadFile(
      bucket: 'school-assets',
      filePath: filePath,
      folder: 'logos/$schoolId',
      fileName: 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  /// Upload student document
  Future<String> uploadStudentDocument({
    required String studentId,
    required String filePath,
    String? documentType,
  }) async {
    final folder = documentType != null
        ? 'documents/$studentId/$documentType'
        : 'documents/$studentId';
    return uploadFile(
      bucket: 'student-documents',
      filePath: filePath,
      folder: folder,
    );
  }

  /// Delete a file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get public URL for a file
  String getPublicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
