import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'offline_sync_queue.g.dart';

@HiveType(typeId: 100)
class OfflineSyncQueue extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String tableName;
  
  @HiveField(2)
  final String operation;
  
  @HiveField(3)
  final Map<String, dynamic> data;
  
  @HiveField(4)
  final String syncStatus;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime? lastAttemptAt;
  
  @HiveField(7)
  final int attemptCount;
  
  @HiveField(8)
  final String? errorMessage;
  
  @HiveField(9)
  final String? conflictData;
  
  @HiveField(10)
  final String schoolId;

  const OfflineSyncQueue({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.data,
    required this.syncStatus,
    required this.createdAt,
    required this.schoolId,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.errorMessage,
    this.conflictData,
  });

  factory OfflineSyncQueue.create({
    required String tableName,
    required String operation,
    required Map<String, dynamic> data,
    required String schoolId,
  }) {
    return OfflineSyncQueue(
      id: '${DateTime.now().millisecondsSinceEpoch}_${tableName}_$operation',
      tableName: tableName,
      operation: operation,
      data: data,
      syncStatus: 'pending',
      createdAt: DateTime.now(),
      schoolId: schoolId,
    );
  }

  OfflineSyncQueue copyWith({
    String? syncStatus,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? errorMessage,
    String? conflictData,
  }) {
    return OfflineSyncQueue(
      id: id,
      tableName: tableName,
      operation: operation,
      data: data,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      schoolId: schoolId,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: errorMessage ?? this.errorMessage,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'operation': operation,
      'data': data,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'attempt_count': attemptCount,
      'error_message': errorMessage,
      'conflict_data': conflictData,
      'school_id': schoolId,
    };
  }

  factory OfflineSyncQueue.fromMap(Map<String, dynamic> map) {
    return OfflineSyncQueue(
      id: map['id'] as String,
      tableName: map['table_name'] as String,
      operation: map['operation'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      syncStatus: map['sync_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      schoolId: map['school_id'] as String,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
      attemptCount: (map['attempt_count'] as int?) ?? 0,
      errorMessage: map['error_message'] as String?,
      conflictData: map['conflict_data'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tableName,
        operation,
        data,
        syncStatus,
        createdAt,
        lastAttemptAt,
        attemptCount,
        errorMessage,
        conflictData,
        schoolId,
      ];
}