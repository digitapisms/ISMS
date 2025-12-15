import 'package:equatable/equatable.dart';

class AssignmentAttachment extends Equatable {
  const AssignmentAttachment({
    required this.id,
    required this.schoolId,
    required this.assignmentId,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.fileType,
    this.uploadedBy,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String assignmentId;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? fileType;
  final String? uploadedBy;
  final DateTime? createdAt;

  factory AssignmentAttachment.fromMap(Map<String, dynamic> map) {
    return AssignmentAttachment(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      assignmentId: map['assignment_id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int?,
      fileType: map['file_type'] as String?,
      uploadedBy: map['uploaded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'assignment_id': assignmentId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(2)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  List<Object?> get props => [
    id,
    schoolId,
    assignmentId,
    fileName,
    filePath,
    fileSize,
    fileType,
    uploadedBy,
    createdAt,
  ];
}
