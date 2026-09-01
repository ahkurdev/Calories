import 'dart:math' as math;

class DailyHealthStatistics {
  const DailyHealthStatistics({
    required this.day,
    required this.targetCalories,
    required this.consumedCalories,
    required this.waterMl,
    required this.waterTargetMl,
    required this.activityMinutes,
    required this.estimatedActivityCalories,
  });

  final DateTime day;
  final int targetCalories;
  final int consumedCalories;
  final int waterMl;
  final int waterTargetMl;
  final int activityMinutes;
  final int estimatedActivityCalories;

  int get remainingCalories => math.max(0, targetCalories - consumedCalories);
  int get overTargetCalories => math.max(0, consumedCalories - targetCalories);

  Map<String, Object?> toAiJson() => {
    'date': _date(day),
    'targetCalories': targetCalories,
    'consumedCalories': consumedCalories,
    'remainingCalories': remainingCalories,
    'overTargetCalories': overTargetCalories,
    'waterMl': waterMl,
    'waterTargetMl': waterTargetMl,
    'activityMinutes': activityMinutes,
    'estimatedActivityCalories': estimatedActivityCalories,
  };
}

class WeeklyHealthStatistics {
  const WeeklyHealthStatistics({
    required this.start,
    required this.endExclusive,
    required this.targetCalories,
    required this.averageCaloriesOnTrackedDays,
    required this.calorieTrackingDays,
    required this.averageWaterOnTrackedDays,
    required this.waterTrackingDays,
    required this.totalActivityMinutes,
    required this.activeDays,
    required this.frequentFoods,
    this.weightChangeKg,
  });

  final DateTime start;
  final DateTime endExclusive;
  final int targetCalories;
  final int averageCaloriesOnTrackedDays;
  final int calorieTrackingDays;
  final int averageWaterOnTrackedDays;
  final int waterTrackingDays;
  final int totalActivityMinutes;
  final int activeDays;
  final double? weightChangeKg;
  final List<String> frequentFoods;

  int get periodDays => endExclusive.difference(start).inDays;

  Map<String, Object?> toAiJson() => {
    'periodStart': _date(start),
    'periodEndInclusive': _date(endExclusive.subtract(const Duration(days: 1))),
    'periodDays': periodDays,
    'targetDailyCalories': targetCalories,
    'averageCaloriesOnTrackedDays': averageCaloriesOnTrackedDays,
    'calorieTrackingDays': calorieTrackingDays,
    'averageWaterMlOnTrackedDays': averageWaterOnTrackedDays,
    'waterTrackingDays': waterTrackingDays,
    'totalActivityMinutes': totalActivityMinutes,
    'activeDays': activeDays,
    'weightChangeKg': weightChangeKg,
    'frequentFoods': frequentFoods,
  };
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
