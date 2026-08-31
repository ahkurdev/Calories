import 'dart:math' as math;

class WeightLog {
  const WeightLog({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
    this.note,
  });

  factory WeightLog.fromJson(Map<String, Object?> json) => WeightLog(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    weightKg: (json['weight_kg']! as num).toDouble(),
    note: json['note'] as String?,
    loggedAt: DateTime.parse(json['logged_at']! as String),
  );

  final String id;
  final String userId;
  final double weightKg;
  final String? note;
  final DateTime loggedAt;

  Map<String, Object?> toInsertJson(String ownerId) => {
    'user_id': ownerId,
    'weight_kg': weightKg,
    'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
    'logged_at': loggedAt.toUtc().toIso8601String(),
  };
}

class WaterLog {
  const WaterLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterLog.fromJson(Map<String, Object?> json) => WaterLog(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    amountMl: (json['amount_ml']! as num).toInt(),
    loggedAt: DateTime.parse(json['logged_at']! as String),
  );

  final String id;
  final String userId;
  final int amountMl;
  final DateTime loggedAt;

  Map<String, Object?> toInsertJson(String ownerId) => {
    'user_id': ownerId,
    'amount_ml': amountMl,
    'logged_at': loggedAt.toUtc().toIso8601String(),
  };
}

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.durationMinutes,
    required this.loggedAt,
    this.distanceKm,
    this.estimatedCalories,
  });

  factory ActivityLog.fromJson(Map<String, Object?> json) => ActivityLog(
    id: json['id']! as String,
    userId: json['user_id']! as String,
    activityType: json['activity_type']! as String,
    durationMinutes: (json['duration_minutes']! as num).toInt(),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    estimatedCalories: (json['estimated_calories'] as num?)?.toDouble(),
    loggedAt: DateTime.parse(json['logged_at']! as String),
  );

  final String id;
  final String userId;
  final String activityType;
  final int durationMinutes;
  final double? distanceKm;
  final double? estimatedCalories;
  final DateTime loggedAt;

  Map<String, Object?> toInsertJson(String ownerId) => {
    'user_id': ownerId,
    'activity_type': activityType.trim(),
    'duration_minutes': durationMinutes,
    'distance_km': distanceKm,
    'estimated_calories': estimatedCalories,
    'logged_at': loggedAt.toUtc().toIso8601String(),
  };
}

class WeightProgress {
  const WeightProgress({
    required this.totalChangeKg,
    required this.remainingKg,
    required this.progress,
  });

  factory WeightProgress.calculate({
    required double startingWeightKg,
    required double currentWeightKg,
    required double targetWeightKg,
  }) {
    final totalDistance = (targetWeightKg - startingWeightKg).abs();
    final travelled = (currentWeightKg - startingWeightKg).abs();
    final rawProgress = totalDistance == 0 ? 1.0 : travelled / totalDistance;
    return WeightProgress(
      totalChangeKg: currentWeightKg - startingWeightKg,
      remainingKg: (targetWeightKg - currentWeightKg).abs(),
      progress: rawProgress.clamp(0, 1),
    );
  }

  final double totalChangeKg;
  final double remainingKg;
  final double progress;
}

class WaterSummary {
  const WaterSummary({required this.consumedMl, required this.targetMl});

  final int consumedMl;
  final int targetMl;

  int get remainingMl => math.max(0, targetMl - consumedMl);
  double get progress =>
      targetMl <= 0 ? 0 : (consumedMl / targetMl).clamp(0, 1);
}
