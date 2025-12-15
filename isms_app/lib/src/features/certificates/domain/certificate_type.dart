enum CertificateType {
  leaving,
  character,
  appreciation,
  achievement,
  participation,
  completion,
  transfer,
  merit,
  excellence,
}

extension CertificateTypeX on CertificateType {
  String get dbValue {
    switch (this) {
      case CertificateType.leaving:
        return 'leaving';
      case CertificateType.character:
        return 'character';
      case CertificateType.appreciation:
        return 'appreciation';
      case CertificateType.achievement:
        return 'achievement';
      case CertificateType.participation:
        return 'participation';
      case CertificateType.completion:
        return 'completion';
      case CertificateType.transfer:
        return 'transfer';
      case CertificateType.merit:
        return 'merit';
      case CertificateType.excellence:
        return 'excellence';
    }
  }

  String get displayName {
    switch (this) {
      case CertificateType.leaving:
        return 'School Leaving Certificate';
      case CertificateType.character:
        return 'Character Certificate';
      case CertificateType.appreciation:
        return 'Appreciation Certificate';
      case CertificateType.achievement:
        return 'Achievement Certificate';
      case CertificateType.participation:
        return 'Participation Certificate';
      case CertificateType.completion:
        return 'Course Completion Certificate';
      case CertificateType.transfer:
        return 'Transfer Certificate';
      case CertificateType.merit:
        return 'Merit Certificate';
      case CertificateType.excellence:
        return 'Excellence Certificate';
    }
  }

  static CertificateType fromDb(String value) {
    switch (value) {
      case 'leaving':
        return CertificateType.leaving;
      case 'character':
        return CertificateType.character;
      case 'appreciation':
        return CertificateType.appreciation;
      case 'achievement':
        return CertificateType.achievement;
      case 'participation':
        return CertificateType.participation;
      case 'completion':
        return CertificateType.completion;
      case 'transfer':
        return CertificateType.transfer;
      case 'merit':
        return CertificateType.merit;
      case 'excellence':
        return CertificateType.excellence;
      default:
        return CertificateType.leaving;
    }
  }
}

enum RecipientType {
  student,
  staff,
}

extension RecipientTypeX on RecipientType {
  String get dbValue {
    switch (this) {
      case RecipientType.student:
        return 'student';
      case RecipientType.staff:
        return 'staff';
    }
  }

  String get displayName {
    switch (this) {
      case RecipientType.student:
        return 'Student';
      case RecipientType.staff:
        return 'Staff';
    }
  }

  static RecipientType fromDb(String value) {
    switch (value) {
      case 'student':
        return RecipientType.student;
      case 'staff':
        return RecipientType.staff;
      default:
        return RecipientType.student;
    }
  }
}

enum TemplateType {
  student,
  staff,
  both,
}

extension TemplateTypeX on TemplateType {
  String get dbValue {
    switch (this) {
      case TemplateType.student:
        return 'student';
      case TemplateType.staff:
        return 'staff';
      case TemplateType.both:
        return 'both';
    }
  }

  String get displayName {
    switch (this) {
      case TemplateType.student:
        return 'Student Only';
      case TemplateType.staff:
        return 'Staff Only';
      case TemplateType.both:
        return 'Student & Staff';
    }
  }

  static TemplateType fromDb(String value) {
    switch (value) {
      case 'student':
        return TemplateType.student;
      case 'staff':
        return TemplateType.staff;
      case 'both':
        return TemplateType.both;
      default:
        return TemplateType.student;
    }
  }
}

enum FieldType {
  text,
  date,
  number,
  image,
  signature,
}

extension FieldTypeX on FieldType {
  String get dbValue {
    switch (this) {
      case FieldType.text:
        return 'text';
      case FieldType.date:
        return 'date';
      case FieldType.number:
        return 'number';
      case FieldType.image:
        return 'image';
      case FieldType.signature:
        return 'signature';
    }
  }

  static FieldType fromDb(String value) {
    switch (value) {
      case 'text':
        return FieldType.text;
      case 'date':
        return FieldType.date;
      case 'number':
        return FieldType.number;
      case 'image':
        return FieldType.image;
      case 'signature':
        return FieldType.signature;
      default:
        return FieldType.text;
    }
  }
}

