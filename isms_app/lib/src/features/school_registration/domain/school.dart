import 'package:equatable/equatable.dart';

class School extends Equatable {
  const School({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.logoUrl,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.website,
    this.slogan,
    this.schoolType,
    this.groupName,
    this.boardsOrganizations,
    this.charityFoundationType,
    this.status,
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
    this.primaryColor,
    this.secondaryColor,
    this.schoolCode,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.googlePlaceId,
    this.registrationType,
    this.registrationNumber,
    this.registrationBoard,
    this.province,
    this.district,
    this.tehsil,
    this.phoneSecondary,
    this.phoneLandline,
    this.whatsappNumber,
    this.faxNumber,
    this.mediumOfInstruction,
    this.educationLevels,
    this.genderType,
    this.establishedYear,
    this.totalStudentsCapacity,
    this.cnicNumber,
    this.ntnNumber,
    this.institutionTypeId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? website;
  final String? slogan;
  final String? schoolType; // individual, group
  final String? groupName;
  final String?
  boardsOrganizations; // O-Levels, boards, organizations registered to
  final String?
  charityFoundationType; // charity_based, foundation, part_of_foundation
  final String? status; // pending, active, suspended, expired
  final String? subscriptionPlan; // free, basic, premium, enterprise
  final DateTime? subscriptionExpiresAt;
  final String? primaryColor; // Hex color code
  final String? secondaryColor; // Hex color code
  final String? schoolCode; // Unique code for user registration
  final DateTime? createdAt;
  // Location fields
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final String? googlePlaceId;
  // Registration type fields
  final String?
  registrationType; // private, public, semi_private, madrassa, international
  final String? registrationNumber;
  final String? registrationBoard; // FBISE, Punjab Board, Sindh Board, etc.
  // Pakistan-specific location fields
  final String? province; // Punjab, Sindh, KPK, Balochistan, etc.
  final String? district;
  final String? tehsil;
  // Contact fields
  final String? phoneSecondary;
  final String? phoneLandline;
  final String? whatsappNumber;
  final String? faxNumber;
  // Education fields
  final String? mediumOfInstruction; // english, urdu, bilingual
  final List<String>?
  educationLevels; // primary, middle, secondary, higher_secondary
  final String? genderType; // boys, girls, co_education
  final int? establishedYear;
  final int? totalStudentsCapacity;
  // Verification fields
  final String? cnicNumber; // Principal's CNIC
  final String? ntnNumber; // National Tax Number

  // Institution personalization
  final String? institutionTypeId; // Foreign key to institution_types

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      logoUrl: map['logo_url'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zip_code'] as String?,
      country: map['country'] as String?,
      website: map['website'] as String?,
      slogan: map['slogan'] as String?,
      schoolType: map['school_type'] as String?,
      groupName: map['group_name'] as String?,
      boardsOrganizations: map['boards_organizations'] as String?,
      charityFoundationType: map['charity_foundation_type'] as String?,
      status: map['status'] as String?,
      subscriptionPlan: map['subscription_plan'] as String?,
      subscriptionExpiresAt: map['subscription_expires_at'] != null
          ? DateTime.parse(map['subscription_expires_at'])
          : null,
      primaryColor: map['primary_color'] as String?,
      secondaryColor: map['secondary_color'] as String?,
      schoolCode: map['school_code'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      locationAddress: map['location_address'] as String?,
      googlePlaceId: map['google_place_id'] as String?,
      registrationType: map['registration_type'] as String?,
      registrationNumber: map['registration_number'] as String?,
      registrationBoard: map['registration_board'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      tehsil: map['tehsil'] as String?,
      phoneSecondary: map['phone_secondary'] as String?,
      phoneLandline: map['phone_landline'] as String?,
      whatsappNumber: map['whatsapp_number'] as String?,
      faxNumber: map['fax_number'] as String?,
      mediumOfInstruction: map['medium_of_instruction'] as String?,
      educationLevels: map['education_levels'] != null
          ? (map['education_levels'] as List).cast<String>()
          : null,
      genderType: map['gender_type'] as String?,
      establishedYear: map['established_year'] as int?,
      totalStudentsCapacity: map['total_students_capacity'] as int?,
      cnicNumber: map['cnic_number'] as String?,
      ntnNumber: map['ntn_number'] as String?,
      institutionTypeId: map['institution_type_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'logo_url': logoUrl,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'website': website,
      'slogan': slogan,
      'school_type': schoolType,
      'group_name': groupName,
      'boards_organizations': boardsOrganizations,
      'charity_foundation_type': charityFoundationType,
      'status': status,
      'subscription_plan': subscriptionPlan,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'school_code': schoolCode,
      'created_at': createdAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'google_place_id': googlePlaceId,
      'registration_type': registrationType,
      'registration_number': registrationNumber,
      'registration_board': registrationBoard,
      'province': province,
      'district': district,
      'tehsil': tehsil,
      'phone_secondary': phoneSecondary,
      'phone_landline': phoneLandline,
      'whatsapp_number': whatsappNumber,
      'fax_number': faxNumber,
      'medium_of_instruction': mediumOfInstruction,
      'education_levels': educationLevels,
      'gender_type': genderType,
      'established_year': establishedYear,
      'total_students_capacity': totalStudentsCapacity,
      'cnic_number': cnicNumber,
      'ntn_number': ntnNumber,
      'institution_type_id': institutionTypeId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    logoUrl,
    address,
    city,
    state,
    zipCode,
    country,
    website,
    slogan,
    schoolType,
    groupName,
    boardsOrganizations,
    charityFoundationType,
    status,
    subscriptionPlan,
    subscriptionExpiresAt,
    primaryColor,
    secondaryColor,
    schoolCode,
    createdAt,
    latitude,
    longitude,
    locationAddress,
    googlePlaceId,
    registrationType,
    registrationNumber,
    registrationBoard,
    province,
    district,
    tehsil,
    phoneSecondary,
    phoneLandline,
    whatsappNumber,
    faxNumber,
    mediumOfInstruction,
    educationLevels,
    genderType,
    establishedYear,
    totalStudentsCapacity,
    cnicNumber,
    ntnNumber,
    institutionTypeId,
  ];
}
