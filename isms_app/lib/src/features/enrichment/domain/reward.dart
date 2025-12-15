enum RewardType { badge, privilege, physical, virtual }

enum StudentRewardStatus { pending, fulfilled, cancelled }

class ActivityReward {
  final String id;
  final String schoolId;
  final String name;
  final String? description;
  final int pointsRequired;
  final RewardType? rewardType;
  final String? iconUrl;
  final bool isActive;
  final int? stockQuantity;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityReward({
    required this.id,
    required this.schoolId,
    required this.name,
    this.description,
    required this.pointsRequired,
    this.rewardType,
    this.iconUrl,
    required this.isActive,
    this.stockQuantity,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityReward.fromMap(Map<String, dynamic> map) {
    return ActivityReward(
      id: map['id'] as String,
      schoolId: map['school_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      pointsRequired: (map['points_required'] as num?)?.toInt() ?? 0,
      rewardType: map['reward_type'] != null
          ? RewardType.values.firstWhere(
              (e) => e.name == map['reward_type'],
              orElse: () => RewardType.badge,
            )
          : null,
      iconUrl: map['icon_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      stockQuantity: map['stock_quantity'] as int?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'description': description,
      'points_required': pointsRequired,
      'reward_type': rewardType?.name,
      'icon_url': iconUrl,
      'is_active': isActive,
      'stock_quantity': stockQuantity,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StudentReward {
  final String id;
  final String studentId;
  final String rewardId;
  final int pointsSpent;
  final DateTime redeemedAt;
  final StudentRewardStatus status;
  final String? fulfilledBy;
  final DateTime? fulfilledAt;
  final String? notes;
  final DateTime createdAt;

  StudentReward({
    required this.id,
    required this.studentId,
    required this.rewardId,
    required this.pointsSpent,
    required this.redeemedAt,
    required this.status,
    this.fulfilledBy,
    this.fulfilledAt,
    this.notes,
    required this.createdAt,
  });

  factory StudentReward.fromMap(Map<String, dynamic> map) {
    return StudentReward(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      rewardId: map['reward_id'] as String,
      pointsSpent: (map['points_spent'] as num?)?.toInt() ?? 0,
      redeemedAt: DateTime.parse(map['redeemed_at'] as String),
      status: StudentRewardStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StudentRewardStatus.pending,
      ),
      fulfilledBy: map['fulfilled_by'] as String?,
      fulfilledAt: map['fulfilled_at'] != null
          ? DateTime.parse(map['fulfilled_at'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'reward_id': rewardId,
      'points_spent': pointsSpent,
      'redeemed_at': redeemedAt.toIso8601String(),
      'status': status.name,
      'fulfilled_by': fulfilledBy,
      'fulfilled_at': fulfilledAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StudentEngagementStats {
  final String id;
  final String studentId;
  final String schoolId;
  final String metricKey;
  final double metricValue;
  final String period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Map<String, dynamic> metadata;
  final DateTime lastUpdated;
  final DateTime createdAt;

  StudentEngagementStats({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.metricKey,
    required this.metricValue,
    required this.period,
    this.periodStart,
    this.periodEnd,
    required this.metadata,
    required this.lastUpdated,
    required this.createdAt,
  });

  factory StudentEngagementStats.fromMap(Map<String, dynamic> map) {
    return StudentEngagementStats(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      schoolId: map['school_id'] as String,
      metricKey: map['metric_key'] as String,
      metricValue: (map['metric_value'] as num?)?.toDouble() ?? 0.0,
      period: map['period'] as String,
      periodStart: map['period_start'] != null
          ? DateTime.parse(map['period_start'] as String)
          : null,
      periodEnd: map['period_end'] != null
          ? DateTime.parse(map['period_end'] as String)
          : null,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'school_id': schoolId,
      'metric_key': metricKey,
      'metric_value': metricValue,
      'period': period,
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
      'metadata': metadata,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
