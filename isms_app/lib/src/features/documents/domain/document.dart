class Document {
  final String id;
  final String schoolId;
  final String title;
  final String? description;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String? documentType; // Maps to document_type in DB
  final List<String> tags;
  final String? folderId;
  final int? classId; // Maps to class_id in DB
  final int? sectionId; // Maps to section_id in DB
  final List<String> sharedWithUsers;
  final String? accessLevel; // Maps to access_level in DB
  final bool isArchived;
  final int versionNumber;
  final String? previousVersionId; // Maps to previous_version_id in DB
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.schoolId,
    required this.title,
    this.description,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    this.documentType,
    this.tags = const [],
    this.folderId,
    this.classId,
    this.sectionId,
    this.sharedWithUsers = const [],
    this.accessLevel,
    this.isArchived = false,
    this.versionNumber = 1,
    this.previousVersionId,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      documentType: json['document_type'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      folderId: json['folder_id'] as String?,
      classId: json['class_id'] as int?,
      sectionId: json['section_id'] as int?,
      sharedWithUsers: (json['shared_with_users'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      accessLevel: json['access_level'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      versionNumber: json['version_number'] as int? ?? 1,
      previousVersionId: json['previous_version_id'] as String?,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'title': title,
      'description': description,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_size': fileSize,
      'mime_type': mimeType,
      'document_type': documentType,
      'tags': tags,
      'folder_id': folderId,
      'class_id': classId,
      'section_id': sectionId,
      'shared_with_users': sharedWithUsers,
      'access_level': accessLevel,
      'is_archived': isArchived,
      'version_number': versionNumber,
      'previous_version_id': previousVersionId,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

