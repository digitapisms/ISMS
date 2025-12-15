import 'package:equatable/equatable.dart';

import 'book_type.dart';

class ResourceShareInvitation extends Equatable {
  const ResourceShareInvitation({
    required this.id,
    required this.schoolId,
    required this.resourceId,
    required this.inviterId,
    required this.inviteeEmail,
    this.inviteeName,
    this.permissionLevel = PermissionLevel.view,
    this.message,
    this.status = ShareStatus.pending,
    this.shareToken,
    this.expiresAt,
    this.acceptedAt,
    this.acceptedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String resourceId;
  final String inviterId;
  final String inviteeEmail;
  final String? inviteeName;
  final PermissionLevel permissionLevel;
  final String? message;
  final ShareStatus status;
  final String? shareToken;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isAccepted => status == ShareStatus.accepted;
  bool get isPending => status == ShareStatus.pending;

  factory ResourceShareInvitation.fromMap(Map<String, dynamic> map) {
    return ResourceShareInvitation(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      resourceId: map['resource_id'] as String,
      inviterId: map['inviter_id'] as String,
      inviteeEmail: map['invitee_email'] as String,
      inviteeName: map['invitee_name'] as String?,
      permissionLevel: PermissionLevelX.fromDb(map['permission_level'] as String? ?? 'view'),
      message: map['message'] as String?,
      status: ShareStatusX.fromDb(map['status'] as String? ?? 'pending'),
      shareToken: map['share_token'] as String?,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      acceptedBy: map['accepted_by'] as String?,
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
      'inviter_id': inviterId,
      'invitee_email': inviteeEmail,
      'invitee_name': inviteeName,
      'permission_level': permissionLevel.dbValue,
      'message': message,
      'status': status.dbValue,
      'share_token': shareToken,
      'expires_at': expiresAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'accepted_by': acceptedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        resourceId,
        inviterId,
        inviteeEmail,
        inviteeName,
        permissionLevel,
        message,
        status,
        shareToken,
        expiresAt,
        acceptedAt,
        acceptedBy,
        createdAt,
        updatedAt,
      ];
}