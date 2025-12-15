import 'package:equatable/equatable.dart';

class TenantSettings extends Equatable {
  const TenantSettings({
    required this.schoolId,
    required this.timezone,
    required this.locale,
    required this.currency,
    this.academicYearStart,
    this.academicYearEnd,
    this.featureFlags = const {},
    this.preferences = const {},
    this.branding = const {},
  });

  final String schoolId;
  final String timezone;
  final String locale;
  final String currency;
  final DateTime? academicYearStart;
  final DateTime? academicYearEnd;
  final Map<String, dynamic> featureFlags;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> branding;

  factory TenantSettings.fromMap(Map<String, dynamic> map) {
    return TenantSettings(
      schoolId: map['school_id'] as String,
      timezone: map['timezone'] as String? ?? 'Asia/Karachi',
      locale: map['locale'] as String? ?? 'en',
      currency: map['currency'] as String? ?? 'PKR',
      academicYearStart: map['academic_year_start'] != null
          ? DateTime.tryParse(map['academic_year_start'] as String)
          : null,
      academicYearEnd: map['academic_year_end'] != null
          ? DateTime.tryParse(map['academic_year_end'] as String)
          : null,
      featureFlags: map['feature_flags'] != null
          ? Map<String, dynamic>.from(map['feature_flags'] as Map)
          : const {},
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(map['preferences'] as Map)
          : const {},
      branding: map['branding'] != null
          ? Map<String, dynamic>.from(map['branding'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toPayload({
    String? timezoneOverride,
    String? localeOverride,
    String? currencyOverride,
    Map<String, dynamic>? featureFlagsOverride,
    Map<String, dynamic>? preferencesOverride,
  }) {
    final payload = <String, dynamic>{};
    if (timezoneOverride != null) payload['timezone'] = timezoneOverride;
    if (localeOverride != null) payload['locale'] = localeOverride;
    if (currencyOverride != null) payload['currency'] = currencyOverride;
    if (featureFlagsOverride != null) {
      payload['feature_flags'] = featureFlagsOverride;
    }
    if (preferencesOverride != null) {
      payload['preferences'] = preferencesOverride;
    }
    return payload;
  }

  @override
  List<Object?> get props => [
    schoolId,
    timezone,
    locale,
    currency,
    academicYearStart,
    academicYearEnd,
    featureFlags,
    preferences,
    branding,
  ];
}
