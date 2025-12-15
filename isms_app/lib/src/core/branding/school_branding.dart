import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// School branding information
class SchoolBranding {
  const SchoolBranding({
    this.schoolName,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  final String? schoolName;
  final String? logoUrl;
  final Color? primaryColor;
  final Color? secondaryColor;

  SchoolBranding copyWith({
    String? schoolName,
    String? logoUrl,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return SchoolBranding(
      schoolName: schoolName ?? this.schoolName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }
}

/// Provider for school branding
final schoolBrandingProvider = StateNotifierProvider<SchoolBrandingNotifier, SchoolBranding>((ref) {
  return SchoolBrandingNotifier();
});

class SchoolBrandingNotifier extends StateNotifier<SchoolBranding> {
  SchoolBrandingNotifier() : super(const SchoolBranding());

  void updateBranding(SchoolBranding branding) {
    state = branding;
  }
  
  void clear() {
    state = const SchoolBranding();
  }

  void setSchoolName(String? name) {
    state = state.copyWith(schoolName: name);
  }

  void setLogoUrl(String? url) {
    state = state.copyWith(logoUrl: url);
  }

  void setColors(Color? primary, Color? secondary) {
    state = state.copyWith(primaryColor: primary, secondaryColor: secondary);
  }
}

