import 'package:equatable/equatable.dart';

import 'book_type.dart';

class ResourceShareLink extends Equatable {
  const ResourceShareLink({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.createdBy,
    required this.shareToken,
    this.shareType = ShareType.view,
    this.accessLevel = AccessLevel.public,
    this.expiresAt,
    this.maxUses,
    this.currentUses = 0,
    this.passwordHash,
    this.isActive = true,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final String createdBy;
  final String shareToken;
  final ShareType shareType;
  final AccessLevel accessLevel;
  final DateTime? expiresAt;
  final int? maxUses;
  final int currentUses;
  final String? passwordHash;
  final bool isActive;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasReachedMaxUses => maxUses != null && currentUses >= maxUses!;
  bool get isAccessible => isActive && !isExpired && !hasReachedMaxUses;

  factory ResourceShareLink.fromMap(Map<String, dynamic> map) {
    return ResourceShareLink(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      createdBy: map['created_by'] as String,
      shareToken: map['share_token'] as String,
      shareType: ShareTypeX.fromDb(map['share_type'] as String? ?? 'view'),
      accessLevel: AccessLevelX.fromDb(map['access_level'] as String? ?? 'public'),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      maxUses: map['max_uses'] as int?,
      currentUses: (map['current_uses'] as int?) ?? 0,
      passwordHash: map['password_hash'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      description: map['description'] as String?,
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
      'resource_id': resourceId,
      'created_by': createdBy,
      'share_token': shareToken,
      'share_type': shareType.dbValue,
      'access_level': accessLevel.dbValue,
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
      'current_uses': currentUses,
      'password_hash': passwordHash,
      'is_active': isActive,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        createdBy,
        shareToken,
        shareType,
        accessLevel,
        expiresAt,
        maxUses,
        currentUses,
        passwordHash,
        isActive,
        description,
        createdAt,
        updatedAt,
      ];
}