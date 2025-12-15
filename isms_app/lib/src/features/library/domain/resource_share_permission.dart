import 'package:equatable/equatable.dart';

import 'book_type.dart';

class ResourceSharePermission extends Equatable {
  const ResourceSharePermission({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.grantedBy,
    this.shareLinkId,
    this.userId,
    this.email,
    this.permissionLevel = PermissionLevel.view,
    this.status = ShareStatus.pending,
    this.expiresAt,
    this.accessCount = 0,
    this.lastAccessedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String? shareLinkId;
  final String resourceId;
  final String? userId;
  final String? email;
  final PermissionLevel permissionLevel;
  final String grantedBy;
  final ShareStatus status;
  final DateTime? expiresAt;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActive => status == ShareStatus.accepted && !isExpired;
  String get targetIdentifier => userId ?? email ?? '';

  factory ResourceSharePermission.fromMap(Map<String, dynamic> map) {
    return ResourceSharePermission(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      shareLinkId: map['share_link_id'] as String?,
      resourceId: map['resource_id'] as String,
      userId: map['user_id'] as String?,
      email: map['email'] as String?,
      permissionLevel: PermissionLevelX.fromDb(map['permission_level'] as String? ?? 'view'),
      grantedBy: map['granted_by'] as String,
      status: ShareStatusX.fromDb(map['status'] as String? ?? 'pending'),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      accessCount: (map['access_count'] as int?) ?? 0,
      lastAccessedAt: map['last_accessed_at'] != null
          ? DateTime.parse(map['last_accessed_at'] as String)
          : null,
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
      'share_link_id': shareLinkId,
      'resource_id': resourceId,
      'user_id': userId,
      'email': email,
      'permission_level': permissionLevel.dbValue,
      'granted_by': grantedBy,
      'status': status.dbValue,
      'expires_at': expiresAt?.toIso8601String(),
      'access_count': accessCount,
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        shareLinkId,
        resourceId,
        userId,
        email,
        permissionLevel,
        grantedBy,
        status,
        expiresAt,
        accessCount,
        lastAccessedAt,
        createdAt,
        updatedAt,
      ];
}