import 'package:equatable/equatable.dart';

class StaffProfile extends Equatable {
  const StaffProfile({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.cnicNumber,
    this.maritalStatus,
    this.personalEmail,
    this.personalPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.permanentAddress,
    this.currentAddress,
    this.city,
    this.state,
    this.country = 'Pakistan',
    this.postalCode,
    required this.employmentType,
    this.employmentStatus = 'active',
    required this.joiningDate,
    this.contractStartDate,
    this.contractEndDate,
    this.probationPeriodDays = 90,
    this.teachingType,
    this.courseType,
    this.qualification,
    this.specialization,
    this.experienceYears,
    this.monthlySalary,
    this.hourlyRate,
    this.bankAccountNumber,
    this.bankName,
    this.bankBranch,
    this.employeeId,
    required this.designation,
    this.department,
    this.reportingTo,
    this.branchId,
    this.profilePictureUrl,
    this.resumeUrl,
    this.qualificationDocuments = const [],
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String userId;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? cnicNumber;
  final String? maritalStatus;
  final String? personalEmail;
  final String? personalPhone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? permanentAddress;
  final String? currentAddress;
  final String? city;
  final String? state;
  final String country;
  final String? postalCode;
  final String employmentType;
  final String employmentStatus;
  final DateTime joiningDate;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final int probationPeriodDays;
  final String? teachingType;
  final String? courseType;
  final String? qualification;
  final String? specialization;
  final int? experienceYears;
  final double? monthlySalary;
  final double? hourlyRate;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankBranch;
  final String? employeeId;
  final String designation;
  final String? department;
  final String? reportingTo;
  final String? branchId;
  final String? profilePictureUrl;
  final String? resumeUrl;
  final List<Map<String, dynamic>> qualificationDocuments;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StaffProfile.fromMap(Map<String, dynamic> map) {
    return StaffProfile(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      gender: map['gender'] as String?,
      cnicNumber: map['cnic_number'] as String?,
      maritalStatus: map['marital_status'] as String?,
      personalEmail: map['personal_email'] as String?,
      personalPhone: map['personal_phone'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      emergencyContactRelation: map['emergency_contact_relation'] as String?,
      permanentAddress: map['permanent_address'] as String?,
      currentAddress: map['current_address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String? ?? 'Pakistan',
      postalCode: map['postal_code'] as String?,
      employmentType: map['employment_type'] as String,
      employmentStatus: map['employment_status'] as String? ?? 'active',
      joiningDate: DateTime.parse(map['joining_date'] as String),
      contractStartDate: map['contract_start_date'] != null
          ? DateTime.parse(map['contract_start_date'] as String)
          : null,
      contractEndDate: map['contract_end_date'] != null
          ? DateTime.parse(map['contract_end_date'] as String)
          : null,
      probationPeriodDays: map['probation_period_days'] as int? ?? 90,
      teachingType: map['teaching_type'] as String?,
      courseType: map['course_type'] as String?,
      qualification: map['qualification'] as String?,
      specialization: map['specialization'] as String?,
      experienceYears: map['experience_years'] as int?,
      monthlySalary: (map['monthly_salary'] as num?)?.toDouble(),
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble(),
      bankAccountNumber: map['bank_account_number'] as String?,
      bankName: map['bank_name'] as String?,
      bankBranch: map['bank_branch'] as String?,
      employeeId: map['employee_id'] as String?,
      designation: map['designation'] as String,
      department: map['department'] as String?,
      reportingTo: map['reporting_to'] as String?,
      branchId: map['branch_id'] as String?,
      profilePictureUrl: map['profile_picture_url'] as String?,
      resumeUrl: map['resume_url'] as String?,
      qualificationDocuments: (map['qualification_documents'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
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
      'user_id': userId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'cnic_number': cnicNumber,
      'marital_status': maritalStatus,
      'personal_email': personalEmail,
      'personal_phone': personalPhone,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'permanent_address': permanentAddress,
      'current_address': currentAddress,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'employment_type': employmentType,
      'employment_status': employmentStatus,
      'joining_date': joiningDate.toIso8601String(),
      'contract_start_date': contractStartDate?.toIso8601String(),
      'contract_end_date': contractEndDate?.toIso8601String(),
      'probation_period_days': probationPeriodDays,
      'teaching_type': teachingType,
      'course_type': courseType,
      'qualification': qualification,
      'specialization': specialization,
      'experience_years': experienceYears,
      'monthly_salary': monthlySalary,
      'hourly_rate': hourlyRate,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'employee_id': employeeId,
      'designation': designation,
      'department': department,
      'reporting_to': reportingTo,
      'branch_id': branchId,
      'profile_picture_url': profilePictureUrl,
      'resume_url': resumeUrl,
      'qualification_documents': qualificationDocuments,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  StaffProfile copyWith({
    String? id,
    String? schoolId,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? cnicNumber,
    String? maritalStatus,
    String? personalEmail,
    String? personalPhone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? permanentAddress,
    String? currentAddress,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? employmentType,
    String? employmentStatus,
    DateTime? joiningDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    int? probationPeriodDays,
    String? teachingType,
    String? courseType,
    String? qualification,
    String? specialization,
    int? experienceYears,
    double? monthlySalary,
    double? hourlyRate,
    String? bankAccountNumber,
    String? bankName,
    String? bankBranch,
    String? employeeId,
    String? designation,
    String? department,
    String? reportingTo,
    String? branchId,
    String? profilePictureUrl,
    String? resumeUrl,
    List<Map<String, dynamic>>? qualificationDocuments,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffProfile(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      personalEmail: personalEmail ?? this.personalEmail,
      personalPhone: personalPhone ?? this.personalPhone,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      currentAddress: currentAddress ?? this.currentAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      employmentType: employmentType ?? this.employmentType,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      joiningDate: joiningDate ?? this.joiningDate,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      probationPeriodDays: probationPeriodDays ?? this.probationPeriodDays,
      teachingType: teachingType ?? this.teachingType,
      courseType: courseType ?? this.courseType,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      bankBranch: bankBranch ?? this.bankBranch,
      employeeId: employeeId ?? this.employeeId,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      reportingTo: reportingTo ?? this.reportingTo,
      branchId: branchId ?? this.branchId,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      qualificationDocuments: qualificationDocuments ?? this.qualificationDocuments,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        userId,
        fullName,
        dateOfBirth,
        gender,
        cnicNumber,
        maritalStatus,
        personalEmail,
        personalPhone,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        permanentAddress,
        currentAddress,
        city,
        state,
        country,
        postalCode,
        employmentType,
        employmentStatus,
        joiningDate,
        contractStartDate,
        contractEndDate,
        probationPeriodDays,
        teachingType,
        courseType,
        qualification,
        specialization,
        experienceYears,
        monthlySalary,
        hourlyRate,
        bankAccountNumber,
        bankName,
        bankBranch,
        employeeId,
        designation,
        department,
        reportingTo,
        branchId,
        profilePictureUrl,
        resumeUrl,
        qualificationDocuments,
        isActive,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}