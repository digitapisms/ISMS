import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/report_trend_point.dart';
import '../domain/school_report_overview.dart';

class ReportsRepository {
  SupabaseClient get _client => SupabaseManager.client;

  Future<SchoolReportOverview> fetchOverview(String schoolId) async {
    final result = await _client.rpc(
      'get_school_report_overview',
      params: {'p_school_id': schoolId},
    );

    if (result is Map) {
      return SchoolReportOverview.fromMap(Map<String, dynamic>.from(result));
    }

    throw Exception('Unexpected overview payload: $result');
  }

  Future<List<ReportTrendPoint>> fetchTrends({
    required String schoolId,
    int days = 30,
  }) async {
    final response = await _client.rpc(
      'get_school_report_timeseries',
      params: {'p_school_id': schoolId, 'p_days': days},
    );

    if (response is List) {
      return response
          .map(
            (raw) =>
                ReportTrendPoint.fromMap(Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
    }

    return const [];
  }
}
