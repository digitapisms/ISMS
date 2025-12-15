import 'package:equatable/equatable.dart';

class GlobalAnalytics extends Equatable {
  const GlobalAnalytics({
    required this.totalSchools,
    required this.totalStudents,
    required this.totalApplications,
    required this.activeSchools,
    required this.pendingSchools,
    required this.totalUsers,
    required this.planDistribution,
  });

  final int totalSchools;
  final int totalStudents;
  final int totalApplications;
  final int activeSchools;
  final int pendingSchools;
  final int totalUsers;
  final Map<String, int> planDistribution;

  factory GlobalAnalytics.empty() => const GlobalAnalytics(
    totalSchools: 0,
    totalStudents: 0,
    totalApplications: 0,
    activeSchools: 0,
    pendingSchools: 0,
    totalUsers: 0,
    planDistribution: {},
  );

  @override
  List<Object?> get props => [
    totalSchools,
    totalStudents,
    totalApplications,
    activeSchools,
    pendingSchools,
    totalUsers,
    planDistribution,
  ];
}
