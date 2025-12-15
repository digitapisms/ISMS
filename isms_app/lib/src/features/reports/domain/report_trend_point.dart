import 'package:equatable/equatable.dart';

class ReportTrendPoint extends Equatable {
  const ReportTrendPoint({
    required this.date,
    required this.metric,
    required this.value,
  });

  final DateTime date;
  final String metric;
  final int value;

  factory ReportTrendPoint.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ReportTrendPoint(
      date: parseDate(map['bucket_date']),
      metric: (map['metric'] as String?) ?? 'students',
      value: _asInt(map['value']),
    );
  }

  @override
  List<Object?> get props => [date, metric, value];

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
