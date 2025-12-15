// Base class for all certificate-specific data
abstract class CertificateData {
  Map<String, dynamic> toJson();
  String get type;
}

// Experience Certificate Data
class ExperienceCertificateData implements CertificateData {
  final String position;
  final String department;
  final DateTime employmentStartDate;
  final DateTime employmentEndDate;
  final String responsibilities;
  final String achievements;
  final String supervisorName;
  final String supervisorPosition;
  final String reasonForLeaving;
  final bool isEligibleForRehire;

  ExperienceCertificateData({
    required this.position,
    required this.department,
    required this.employmentStartDate,
    required this.employmentEndDate,
    required this.responsibilities,
    required this.achievements,
    required this.supervisorName,
    required this.supervisorPosition,
    required this.reasonForLeaving,
    this.isEligibleForRehire = true,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'position': position,
      'department': department,
      'employmentStartDate': employmentStartDate.toIso8601String(),
      'employmentEndDate': employmentEndDate.toIso8601String(),
      'responsibilities': responsibilities,
      'achievements': achievements,
      'supervisorName': supervisorName,
      'supervisorPosition': supervisorPosition,
      'reasonForLeaving': reasonForLeaving,
      'isEligibleForRehire': isEligibleForRehire,
    };
  }

  @override
  String get type => 'experience';

  factory ExperienceCertificateData.fromJson(Map<String, dynamic> json) {
    return ExperienceCertificateData(
      position: json['position'] as String,
      department: json['department'] as String,
      employmentStartDate: DateTime.parse(
        json['employmentStartDate'] as String,
      ),
      employmentEndDate: DateTime.parse(json['employmentEndDate'] as String),
      responsibilities: json['responsibilities'] as String,
      achievements: json['achievements'] as String,
      supervisorName: json['supervisorName'] as String,
      supervisorPosition: json['supervisorPosition'] as String,
      reasonForLeaving: json['reasonForLeaving'] as String,
      isEligibleForRehire: json['isEligibleForRehire'] as bool? ?? true,
    );
  }
}

// Educational Certificate Data
class EducationalCertificateData implements CertificateData {
  final String programName;
  final String programDuration;
  final DateTime enrollmentDate;
  final DateTime completionDate;
  final String gradeObtained;
  final String totalMarks;
  final String division;
  final String institutionName;
  final String boardUniversity;
  final bool isRegularStudent;

  EducationalCertificateData({
    required this.programName,
    required this.programDuration,
    required this.enrollmentDate,
    required this.completionDate,
    required this.gradeObtained,
    required this.totalMarks,
    required this.division,
    required this.institutionName,
    required this.boardUniversity,
    this.isRegularStudent = true,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'programName': programName,
      'programDuration': programDuration,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'completionDate': completionDate.toIso8601String(),
      'gradeObtained': gradeObtained,
      'totalMarks': totalMarks,
      'division': division,
      'institutionName': institutionName,
      'boardUniversity': boardUniversity,
      'isRegularStudent': isRegularStudent,
    };
  }

  @override
  String get type => 'educational';

  factory EducationalCertificateData.fromJson(Map<String, dynamic> json) {
    return EducationalCertificateData(
      programName: json['programName'] as String,
      programDuration: json['programDuration'] as String,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      completionDate: DateTime.parse(json['completionDate'] as String),
      gradeObtained: json['gradeObtained'] as String,
      totalMarks: json['totalMarks'] as String,
      division: json['division'] as String,
      institutionName: json['institutionName'] as String,
      boardUniversity: json['boardUniversity'] as String,
      isRegularStudent: json['isRegularStudent'] as bool? ?? true,
    );
  }
}

// Academic Certificate Data
class AcademicCertificateData implements CertificateData {
  final String academicYear;
  final String semester;
  final String courseName;
  final String courseCode;
  final String creditsEarned;
  final String gradePoints;
  final String cgpa;
  final String sgpa;
  final String rankInClass;
  final bool isPassWithDistinction;

  AcademicCertificateData({
    required this.academicYear,
    required this.semester,
    required this.courseName,
    required this.courseCode,
    required this.creditsEarned,
    required this.gradePoints,
    required this.cgpa,
    required this.sgpa,
    required this.rankInClass,
    this.isPassWithDistinction = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'academicYear': academicYear,
      'semester': semester,
      'courseName': courseName,
      'courseCode': courseCode,
      'creditsEarned': creditsEarned,
      'gradePoints': gradePoints,
      'cgpa': cgpa,
      'sgpa': sgpa,
      'rankInClass': rankInClass,
      'isPassWithDistinction': isPassWithDistinction,
    };
  }

  @override
  String get type => 'academic';

  factory AcademicCertificateData.fromJson(Map<String, dynamic> json) {
    return AcademicCertificateData(
      academicYear: json['academicYear'] as String,
      semester: json['semester'] as String,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      creditsEarned: json['creditsEarned'] as String,
      gradePoints: json['gradePoints'] as String,
      cgpa: json['cgpa'] as String,
      sgpa: json['sgpa'] as String,
      rankInClass: json['rankInClass'] as String,
      isPassWithDistinction: json['isPassWithDistinction'] as bool? ?? false,
    );
  }
}

// Factory method to create certificate data from JSON
CertificateData? createCertificateDataFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String?;

  switch (type) {
    case 'experience':
      return ExperienceCertificateData.fromJson(json);
    case 'educational':
      return EducationalCertificateData.fromJson(json);
    case 'academic':
      return AcademicCertificateData.fromJson(json);
    default:
      return null;
  }
}
