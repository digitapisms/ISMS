import 'package:equatable/equatable.dart';

class TenantOnboardingStatus extends Equatable {
  const TenantOnboardingStatus({
    required this.profileComplete,
    required this.brandingComplete,
    required this.classesConfigured,
    required this.staffInvited,
    required this.applicationsEnabled,
  });

  final bool profileComplete;
  final bool brandingComplete;
  final bool classesConfigured;
  final bool staffInvited;
  final bool applicationsEnabled;

  int get completedSteps => [
    profileComplete,
    brandingComplete,
    classesConfigured,
    staffInvited,
    applicationsEnabled,
  ].where((e) => e).length;

  int get totalSteps => 5;

  double get progress => completedSteps / totalSteps;

  bool get isComplete => completedSteps == totalSteps;

  @override
  List<Object?> get props => [
    profileComplete,
    brandingComplete,
    classesConfigured,
    staffInvited,
    applicationsEnabled,
  ];
}
