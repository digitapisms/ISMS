import 'certificate_type.dart';

class CertificateField {
  final String id;
  final String schoolId;
  final String templateId;
  final String fieldName;
  final String fieldLabel;
  final FieldType fieldType;
  final bool isRequired;
  final String? defaultValue;
  final int fieldOrder;

  CertificateField({
    required this.id,
    required this.schoolId,
    required this.templateId,
    required this.fieldName,
    required this.fieldLabel,
    this.fieldType = FieldType.text,
    this.isRequired = false,
    this.defaultValue,
    this.fieldOrder = 0,
  });

  factory CertificateField.fromJson(Map<String, dynamic> json) {
    return CertificateField(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      templateId: json['template_id'] as String,
      fieldName: json['field_name'] as String,
      fieldLabel: json['field_label'] as String,
      fieldType: FieldTypeX.fromDb(json['field_type'] as String? ?? 'text'),
      isRequired: json['is_required'] as bool? ?? false,
      defaultValue: json['default_value'] as String?,
      fieldOrder: json['field_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'template_id': templateId,
      'field_name': fieldName,
      'field_label': fieldLabel,
      'field_type': fieldType.dbValue,
      'is_required': isRequired,
      'default_value': defaultValue,
      'field_order': fieldOrder,
    };
  }
}

