import 'package:equatable/equatable.dart';

import 'book_type.dart';

class DigitalResource extends Equatable {
  const DigitalResource({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.filePath,
    this.bookId,
    this.resourceType = DigitalResourceType.ebook,
    this.fileSize,
    this.fileType,
    this.fileUrl,
    this.thumbnailUrl,
    this.description,
    this.accessLevel = AccessLevel.public,
    this.downloadAllowed = true,
    this.maxDownloads,
    this.currentDownloads = 0,
    this.isActive = true,
    this.uploadedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final int? bookId;
  final String title;
  final DigitalResourceType resourceType;
  final String filePath;
  final int? fileSize;
  final String? fileType;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? description;
  final AccessLevel accessLevel;
  final bool downloadAllowed;
  final int? maxDownloads;
  final int currentDownloads;
  final bool isActive;
  final String? uploadedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DigitalResource.fromMap(Map<String, dynamic> map) {
    return DigitalResource(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      bookId: map['book_id'] as int?,
      title: map['title'] as String,
      resourceType: DigitalResourceTypeX.fromDb(
        map['resource_type'] as String? ?? 'ebook',
      ),
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int?,
      fileType: map['file_type'] as String?,
      fileUrl: map['file_url'] as String?,
      thumbnailUrl: map['thumbnail_url'] as String?,
      description: map['description'] as String?,
      accessLevel: AccessLevelX.fromDb(
        map['access_level'] as String? ?? 'public',
      ),
      downloadAllowed: (map['download_allowed'] as bool?) ?? true,
      maxDownloads: map['max_downloads'] as int?,
      currentDownloads: (map['current_downloads'] as int?) ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
      uploadedBy: map['uploaded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'book_id': bookId,
      'title': title,
      'resource_type': resourceType.dbValue,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'access_level': accessLevel.dbValue,
      'download_allowed': downloadAllowed,
      'max_downloads': maxDownloads,
      'current_downloads': currentDownloads,
      'is_active': isActive,
      'uploaded_by': uploadedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(2)} KB';
    }
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool get canDownload {
    if (!downloadAllowed) return false;
    if (maxDownloads == null) return true;
    return currentDownloads < maxDownloads!;
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        bookId,
        title,
        resourceType,
        filePath,
        fileSize,
        fileType,
        fileUrl,
        thumbnailUrl,
        description,
        accessLevel,
        downloadAllowed,
        maxDownloads,
        currentDownloads,
        isActive,
        uploadedBy,
        createdAt,
        updatedAt,
      ];
}

