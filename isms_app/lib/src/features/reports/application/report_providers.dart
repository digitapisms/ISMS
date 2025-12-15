import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../domain/report_trend_point.dart';
import '../domain/school_report_overview.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

final schoolReportOverviewProvider =
    FutureProvider.family<SchoolReportOverview, String>((ref, schoolId) async {
      final repo = ref.read(reportsRepositoryProvider);
      return repo.fetchOverview(schoolId);
    });

@immutable
class ReportTrendRequest {
  const ReportTrendRequest({required this.schoolId, this.days = 30});

  final String schoolId;
  final int days;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportTrendRequest &&
        other.schoolId == schoolId &&
        other.days == days;
  }

  @override
  int get hashCode => Object.hash(schoolId, days);
}

final schoolReportTrendsProvider =
    FutureProvider.family<List<ReportTrendPoint>, ReportTrendRequest>((
      ref,
      request,
    ) async {
      final repo = ref.read(reportsRepositoryProvider);
      return repo.fetchTrends(schoolId: request.schoolId, days: request.days);
    });
