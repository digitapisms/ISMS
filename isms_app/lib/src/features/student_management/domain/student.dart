class Student {
  const Student({
    required this.id,
    required this.admissionNo,
    required this.fullName,
    this.className,
    this.sectionName,
    this.classId,
    this.sectionId,
    this.status,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.medicalInfo,
    this.avatarUrl,
  });

  final String id;
  final String admissionNo;
  final String fullName;
  final String? className;
  final String? sectionName;
  final int? classId;
  final int? sectionId;
  final String? status;
  final DateTime? dob;
  final String? gender;
  final String? bloodGroup;
  final String? medicalInfo;
  final String? avatarUrl;

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      admissionNo: map['admission_no'] as String,
      fullName: map['full_name'] as String? ?? '',
      className: map['class_name'] as String?,
      sectionName: map['section_name'] as String?,
      classId: map['class_id'] as int?,
      sectionId: map['section_id'] as int?,
      status: map['status'] as String?,
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      gender: map['gender'] as String?,
      bloodGroup: map['blood_group'] as String?,
      medicalInfo: map['medical_info'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admission_no': admissionNo,
      'full_name': fullName,
      'class_id': classId,
      'section_id': sectionId,
      'status': status,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'blood_group': bloodGroup,
      'medical_info': medicalInfo,
      'avatar_url': avatarUrl,
    };
  }
}
