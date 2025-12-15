import 'dart:typed_data';

import '../network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling file uploads to Supabase Storage
class FileUploadService {
  final SupabaseClient _client = SupabaseManager.client;

  /// Upload a file to a storage bucket
  /// 
  /// [bucket] - The name of the storage bucket
  /// [path] - The path within the bucket (e.g., 'students/photos/student-id.jpg')
  /// [fileBytes] - The file data as bytes
  /// [fileOptions] - Optional file upload options
  /// 
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    FileOptions? fileOptions,
  }) async {
    try {
      // Upload file
      await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: fileOptions ?? const FileOptions(),
      );

      // Get public URL
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload a student photo
  /// 
  /// [studentId] - The student ID
  /// [fileBytes] - The image file data
  /// [fileName] - The original file name (for extension detection)
  /// [schoolId] - Optional school ID for organization
  /// 
  /// Returns the public URL of the uploaded photo
  Future<String> uploadStudentPhoto({
    required String studentId,
    required Uint8List fileBytes,
    required String fileName,
    String? schoolId,
  }) async {
    // Extract file extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('Invalid image format. Only JPG, PNG, and WebP are allowed.');
    }

    // Construct path: students/{schoolId}/photos/{studentId}.{ext}
    final path = schoolId != null
        ? 'students/$schoolId/photos/$studentId.$extension'
        : 'students/photos/$studentId.$extension';

    return uploadFile(
      bucket: 'student-assets',
      path: path,
      fileBytes: fileBytes,
      fileOptions: FileOptions(
        contentType: 'image/$extension',
        upsert: true, // Replace if exists
      ),
    );
  }

  /// Upload a student document
  /// 
  /// [studentId] - The student ID
  /// [documentType] - Type of document (e.g., 'birth_certificate', 'transfer_certificate')
  /// [fileBytes] - The file data
  /// [fileName] - The original file name
  /// [schoolId] - Optional school ID for organization
  /// 
  /// Returns the public URL of the uploaded document
  Future<String> uploadStudentDocument({
    required String studentId,
    required String documentType,
    required Uint8List fileBytes,
    required String fileName,
    String? schoolId,
  }) async {
    // Construct path: students/{schoolId}/documents/{studentId}/{documentType}/{fileName}
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final path = schoolId != null
        ? 'students/$schoolId/documents/$studentId/$documentType/$sanitizedFileName'
        : 'students/documents/$studentId/$documentType/$sanitizedFileName';

    return uploadFile(
      bucket: 'student-documents',
      path: path,
      fileBytes: fileBytes,
      fileOptions: FileOptions(
        upsert: false, // Don't replace - keep versions
      ),
    );
  }

  /// Delete a file from storage
  /// 
  /// [bucket] - The storage bucket name
  /// [path] - The path to the file
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

  /// Delete a student photo
  Future<void> deleteStudentPhoto({
    required String studentId,
    String? schoolId,
    String? currentUrl,
  }) async {
    if (currentUrl == null || currentUrl.isEmpty) return;

    // Extract path from URL
    try {
      final uri = Uri.parse(currentUrl);
      final pathSegments = uri.pathSegments;
      final pathIndex = pathSegments.indexWhere((s) => s == 'student-assets');
      
      if (pathIndex >= 0 && pathIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(pathIndex + 1).join('/');
        await deleteFile(bucket: 'student-assets', path: path);
      }
    } catch (e) {
      // If URL parsing fails, try to construct path
      final extension = currentUrl.split('.').last.split('?').first;
      final path = schoolId != null
          ? 'students/$schoolId/photos/$studentId.$extension'
          : 'students/photos/$studentId.$extension';
      
      await deleteFile(bucket: 'student-assets', path: path);
    }
  }

  /// Get a signed URL for temporary access (useful for private buckets)
  /// 
  /// [bucket] - The storage bucket name
  /// [path] - The path to the file
  /// [expiresIn] - Expiration time in seconds (default: 3600 = 1 hour)
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  }) async {
    try {
      final response = await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return response;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }
}

