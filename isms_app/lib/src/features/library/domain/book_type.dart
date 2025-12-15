enum BookType { physical, digital, both }

extension BookTypeX on BookType {
  String get dbValue {
    switch (this) {
      case BookType.physical:
        return 'physical';
      case BookType.digital:
        return 'digital';
      case BookType.both:
        return 'both';
    }
  }

  String get displayName {
    switch (this) {
      case BookType.physical:
        return 'Physical';
      case BookType.digital:
        return 'Digital';
      case BookType.both:
        return 'Both';
    }
  }

  static BookType fromDb(String value) {
    switch (value) {
      case 'physical':
        return BookType.physical;
      case 'digital':
        return BookType.digital;
      case 'both':
        return BookType.both;
      default:
        return BookType.physical;
    }
  }
}

enum BookCopyStatus { available, issued, reserved, lost, damaged, maintenance }

extension BookCopyStatusX on BookCopyStatus {
  String get dbValue {
    switch (this) {
      case BookCopyStatus.available:
        return 'available';
      case BookCopyStatus.issued:
        return 'issued';
      case BookCopyStatus.reserved:
        return 'reserved';
      case BookCopyStatus.lost:
        return 'lost';
      case BookCopyStatus.damaged:
        return 'damaged';
      case BookCopyStatus.maintenance:
        return 'maintenance';
    }
  }

  static BookCopyStatus fromDb(String value) {
    switch (value) {
      case 'available':
        return BookCopyStatus.available;
      case 'issued':
        return BookCopyStatus.issued;
      case 'reserved':
        return BookCopyStatus.reserved;
      case 'lost':
        return BookCopyStatus.lost;
      case 'damaged':
        return BookCopyStatus.damaged;
      case 'maintenance':
        return BookCopyStatus.maintenance;
      default:
        return BookCopyStatus.available;
    }
  }
}

enum BookCondition { excellent, good, fair, poor, damaged }

extension BookConditionX on BookCondition {
  String get dbValue {
    switch (this) {
      case BookCondition.excellent:
        return 'excellent';
      case BookCondition.good:
        return 'good';
      case BookCondition.fair:
        return 'fair';
      case BookCondition.poor:
        return 'poor';
      case BookCondition.damaged:
        return 'damaged';
    }
  }

  String get displayName {
    switch (this) {
      case BookCondition.excellent:
        return 'Excellent';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
      case BookCondition.poor:
        return 'Poor';
      case BookCondition.damaged:
        return 'Damaged';
    }
  }

  static BookCondition fromDb(String value) {
    switch (value) {
      case 'excellent':
        return BookCondition.excellent;
      case 'good':
        return BookCondition.good;
      case 'fair':
        return BookCondition.fair;
      case 'poor':
        return BookCondition.poor;
      case 'damaged':
        return BookCondition.damaged;
      default:
        return BookCondition.good;
    }
  }
}

enum IssueStatus { issued, returned, overdue, lost }

extension IssueStatusX on IssueStatus {
  String get dbValue {
    switch (this) {
      case IssueStatus.issued:
        return 'issued';
      case IssueStatus.returned:
        return 'returned';
      case IssueStatus.overdue:
        return 'overdue';
      case IssueStatus.lost:
        return 'lost';
    }
  }

  String get displayName {
    switch (this) {
      case IssueStatus.issued:
        return 'Issued';
      case IssueStatus.returned:
        return 'Returned';
      case IssueStatus.overdue:
        return 'Overdue';
      case IssueStatus.lost:
        return 'Lost';
    }
  }

  static IssueStatus fromDb(String value) {
    switch (value) {
      case 'issued':
        return IssueStatus.issued;
      case 'returned':
        return IssueStatus.returned;
      case 'overdue':
        return IssueStatus.overdue;
      case 'lost':
        return IssueStatus.lost;
      default:
        return IssueStatus.issued;
    }
  }
}

enum ReservationStatus { pending, fulfilled, cancelled, expired }

extension ReservationStatusX on ReservationStatus {
  String get dbValue {
    switch (this) {
      case ReservationStatus.pending:
        return 'pending';
      case ReservationStatus.fulfilled:
        return 'fulfilled';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.expired:
        return 'expired';
    }
  }

  static ReservationStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return ReservationStatus.pending;
      case 'fulfilled':
        return ReservationStatus.fulfilled;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'expired':
        return ReservationStatus.expired;
      default:
        return ReservationStatus.pending;
    }
  }
}

enum FineStatus { pending, paid, waived, cancelled }

extension FineStatusX on FineStatus {
  String get dbValue {
    switch (this) {
      case FineStatus.pending:
        return 'pending';
      case FineStatus.paid:
        return 'paid';
      case FineStatus.waived:
        return 'waived';
      case FineStatus.cancelled:
        return 'cancelled';
    }
  }

  static FineStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return FineStatus.pending;
      case 'paid':
        return FineStatus.paid;
      case 'waived':
        return FineStatus.waived;
      case 'cancelled':
        return FineStatus.cancelled;
      default:
        return FineStatus.pending;
    }
  }
}

enum DigitalResourceType { ebook, pdf, audio, video, document }

extension DigitalResourceTypeX on DigitalResourceType {
  String get dbValue {
    switch (this) {
      case DigitalResourceType.ebook:
        return 'ebook';
      case DigitalResourceType.pdf:
        return 'pdf';
      case DigitalResourceType.audio:
        return 'audio';
      case DigitalResourceType.video:
        return 'video';
      case DigitalResourceType.document:
        return 'document';
    }
  }

  String get displayName {
    switch (this) {
      case DigitalResourceType.ebook:
        return 'E-Book';
      case DigitalResourceType.pdf:
        return 'PDF';
      case DigitalResourceType.audio:
        return 'Audio';
      case DigitalResourceType.video:
        return 'Video';
      case DigitalResourceType.document:
        return 'Document';
    }
  }

  static DigitalResourceType fromDb(String value) {
    switch (value) {
      case 'ebook':
        return DigitalResourceType.ebook;
      case 'pdf':
        return DigitalResourceType.pdf;
      case 'audio':
        return DigitalResourceType.audio;
      case 'video':
        return DigitalResourceType.video;
      case 'document':
        return DigitalResourceType.document;
      default:
        return DigitalResourceType.ebook;
    }
  }
}

enum AccessLevel { public, restricted, premium }

enum PermissionLevel { view, download, edit, comment }

enum ShareStatus { pending, accepted, declined, revoked, expired }

enum ShareType { view, download, edit }

extension AccessLevelX on AccessLevel {
  String get dbValue {
    switch (this) {
      case AccessLevel.public:
        return 'public';
      case AccessLevel.restricted:
        return 'restricted';
      case AccessLevel.premium:
        return 'premium';
    }
  }

  static AccessLevel fromDb(String value) {
    switch (value) {
      case 'public':
        return AccessLevel.public;
      case 'restricted':
        return AccessLevel.restricted;
      case 'premium':
        return AccessLevel.premium;
      default:
        return AccessLevel.public;
    }
  }
}

extension PermissionLevelX on PermissionLevel {
  String get dbValue {
    switch (this) {
      case PermissionLevel.view:
        return 'view';
      case PermissionLevel.download:
        return 'download';
      case PermissionLevel.edit:
        return 'edit';
      case PermissionLevel.comment:
        return 'comment';
    }
  }

  static PermissionLevel fromDb(String value) {
    switch (value) {
      case 'view':
        return PermissionLevel.view;
      case 'download':
        return PermissionLevel.download;
      case 'edit':
        return PermissionLevel.edit;
      case 'comment':
        return PermissionLevel.comment;
      default:
        return PermissionLevel.view;
    }
  }
}

extension ShareStatusX on ShareStatus {
  String get dbValue {
    switch (this) {
      case ShareStatus.pending:
        return 'pending';
      case ShareStatus.accepted:
        return 'accepted';
      case ShareStatus.declined:
        return 'declined';
      case ShareStatus.revoked:
        return 'revoked';
      case ShareStatus.expired:
        return 'expired';
    }
  }

  static ShareStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return ShareStatus.pending;
      case 'accepted':
        return ShareStatus.accepted;
      case 'declined':
        return ShareStatus.declined;
      case 'revoked':
        return ShareStatus.revoked;
      case 'expired':
        return ShareStatus.expired;
      default:
        return ShareStatus.pending;
    }
  }
}

extension ShareTypeX on ShareType {
  String get dbValue {
    switch (this) {
      case ShareType.view:
        return 'view';
      case ShareType.download:
        return 'download';
      case ShareType.edit:
        return 'edit';
    }
  }

  static ShareType fromDb(String value) {
    switch (value) {
      case 'view':
        return ShareType.view;
      case 'download':
        return ShareType.download;
      case 'edit':
        return ShareType.edit;
      default:
        return ShareType.view;
    }
  }
}
