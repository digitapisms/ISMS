import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/document.dart';

class DocumentsRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception('School context is required');
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  Future<Document> uploadDocument({
    required String title,
    required File file,
    String? description,
    String? documentType,
    List<String>? tags,
    String? accessLevel,
    int? classId,
    int? sectionId,
    List<String>? sharedWithUsers,
  }) async {
    _requireSchoolId();
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Upload file to Supabase Storage
    final fileName = file.path.split('/').last;
    final filePath = '${_requireSchoolId()}/documents/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final fileBytes = await file.readAsBytes();

    await _client.storage.from('documents').uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(fileName),
            upsert: false,
          ),
        );

    final fileUrl = _client.storage.from('documents').getPublicUrl(filePath);

    // Create document record
    final document = Document(
      id: '',
      schoolId: _requireSchoolId(),
      title: title,
      description: description,
      fileName: fileName,
      filePath: filePath,
      fileUrl: fileUrl,
      fileSize: fileBytes.length,
      mimeType: _getMimeType(fileName),
      documentType: documentType,
      tags: tags ?? [],
      classId: classId,
      sectionId: sectionId,
      sharedWithUsers: sharedWithUsers ?? [],
      accessLevel: accessLevel,
      uploadedBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final response = await _client
        .from('documents')
        .insert(_withSchoolId(document.toJson()))
        .select()
        .single();

    return Document.fromJson(response);
  }

  Future<List<Document>> fetchDocuments({
    String? documentType,
    String? searchQuery,
    bool? isArchived,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('documents')
        .select()
        .eq('school_id', _requireSchoolId());

    if (documentType != null) {
      query = query.eq('document_type', documentType);
    }
    if (isArchived != null) {
      query = query.eq('is_archived', isArchived);
    } else {
      query = query.eq('is_archived', false);
    }

    final response = await query.order('created_at', ascending: false);
    var documents = (response as List)
        .map((json) => Document.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filter by search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      documents = documents.where((doc) {
        return doc.title.toLowerCase().contains(query) ||
            (doc.description?.toLowerCase().contains(query) ?? false) ||
            doc.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return documents;
  }

  Future<Document> updateDocument(Document document) async {
    _requireSchoolId();
    final response = await _client
        .from('documents')
        .update(document.toJson())
        .eq('id', document.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Document.fromJson(response);
  }

  Future<void> deleteDocument(String documentId) async {
    _requireSchoolId();
    // Get document to delete file from storage
    final docResponse = await _client
        .from('documents')
        .select('file_path')
        .eq('id', documentId)
        .eq('school_id', _requireSchoolId())
        .single();

    final filePath = docResponse['file_path'] as String;

    // Delete from storage
    try {
      await _client.storage.from('documents').remove([filePath]);
    } catch (e) {
      // Continue even if file deletion fails
      print('Error deleting file from storage: $e');
    }

    // Delete from database
    await _client
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> archiveDocument(String documentId, bool archive) async {
    _requireSchoolId();
    await _client
        .from('documents')
        .update({'is_archived': archive})
        .eq('id', documentId)
        .eq('school_id', _requireSchoolId());
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}

