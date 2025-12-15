import 'visitor_type.dart';

class Visitor {
  final String id;
  final String schoolId;
  final String? visitorIdNumber;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final VisitorType visitorType;
  final String? companyName;
  final String? photoUrl;
  final String? idDocumentUrl;
  final bool isBlacklisted;
  final String? blacklistReason;
  final DateTime? blacklistedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visitor({
    required this.id,
    required this.schoolId,
    this.visitorIdNumber,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.address,
    this.visitorType = VisitorType.guest,
    this.companyName,
    this.photoUrl,
    this.idDocumentUrl,
    this.isBlacklisted = false,
    this.blacklistReason,
    this.blacklistedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      visitorIdNumber: json['visitor_id_number'] as String?,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      visitorType: VisitorTypeX.fromDb(json['visitor_type'] as String? ?? 'guest'),
      companyName: json['company_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      idDocumentUrl: json['id_document_url'] as String?,
      isBlacklisted: json['is_blacklisted'] as bool? ?? false,
      blacklistReason: json['blacklist_reason'] as String?,
      blacklistedAt: json['blacklisted_at'] != null
          ? DateTime.parse(json['blacklisted_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'visitor_id_number': visitorIdNumber,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'visitor_type': visitorType.dbValue,
      'company_name': companyName,
      'photo_url': photoUrl,
      'id_document_url': idDocumentUrl,
      'is_blacklisted': isBlacklisted,
      'blacklist_reason': blacklistReason,
      'blacklisted_at': blacklistedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

