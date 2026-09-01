import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';

class HealthStatisticsService {
  const HealthStatisticsService();

  DailyHealthStatistics daily({
    required DateTime day,
    required int targetCalories,
    required int waterTargetMl,
    required Iterable<FoodLog> foods,
    required Iterable<WaterLog> water,
    required Iterable<ActivityLog> activities,
  }) {
    final start = _day(day);
    final end = start.add(const Duration(days: 1));
    final dailyFoods = foods.where(
      (item) => _inside(item.loggedAt, start, end),
    );
    final dailyWater = water.where(
      (item) => _inside(item.loggedAt, start, end),
    );
    final dailyActivities = activities.where(
      (item) => _inside(item.loggedAt, start, end),
    );
    return DailyHealthStatistics(
      day: start,
      targetCalories: targetCalories,
      consumedCalories: dailyFoods
          .fold<double>(0, (sum, item) => sum + item.calories)
          .round(),
      waterMl: dailyWater.fold<int>(0, (sum, item) => sum + item.amountMl),
      waterTargetMl: waterTargetMl,
      activityMinutes: dailyActivities.fold<int>(
        0,
        (sum, item) => sum + item.durationMinutes,
      ),
      estimatedActivityCalories: dailyActivities
          .fold<double>(0, (sum, item) => sum + (item.estimatedCalories ?? 0))
          .round(),
    );
  }

  WeeklyHealthStatistics weekly({
    required DateTime start,
    required DateTime endExclusive,
    required int targetCalories,
    required Iterable<FoodLog> foods,
    required Iterable<WaterLog> water,
    required Iterable<ActivityLog> activities,
    required Iterable<WeightLog> weights,
  }) {
    final rangeStart = _day(start);
    final rangeEnd = _day(endExclusive);
    if (!rangeEnd.isAfter(rangeStart)) {
      throw ArgumentError('Akhir periode harus setelah awal periode.');
    }
    final rangeFoods = foods
        .where((item) => _inside(item.loggedAt, rangeStart, rangeEnd))
        .toList(growable: false);
    final rangeWater = water
        .where((item) => _inside(item.loggedAt, rangeStart, rangeEnd))
        .toList(growable: false);
    final rangeActivities = activities
        .where((item) => _inside(item.loggedAt, rangeStart, rangeEnd))
        .toList(growable: false);
    final rangeWeights =
        weights
            .where((item) => _inside(item.loggedAt, rangeStart, rangeEnd))
            .toList()
          ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    final caloriesByDay = <DateTime, double>{};
    final foodCounts = <String, int>{};
    for (final food in rangeFoods) {
      caloriesByDay.update(
        _day(food.loggedAt),
        (value) => value + food.calories,
        ifAbsent: () => food.calories,
      );
      final name = food.foodName.trim();
      if (name.isNotEmpty) {
        foodCounts.update(name, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final waterByDay = <DateTime, int>{};
    for (final item in rangeWater) {
      waterByDay.update(
        _day(item.loggedAt),
        (value) => value + item.amountMl,
        ifAbsent: () => item.amountMl,
      );
    }
    final activeDays = rangeActivities
        .map((item) => _day(item.loggedAt))
        .toSet();
    final frequent = foodCounts.keys.toList()
      ..sort((a, b) {
        final byCount = foodCounts[b]!.compareTo(foodCounts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return WeeklyHealthStatistics(
      start: rangeStart,
      endExclusive: rangeEnd,
      targetCalories: targetCalories,
      averageCaloriesOnTrackedDays: _average(caloriesByDay.values),
      calorieTrackingDays: caloriesByDay.length,
      averageWaterOnTrackedDays: _average(waterByDay.values),
      waterTrackingDays: waterByDay.length,
      totalActivityMinutes: rangeActivities.fold<int>(
        0,
        (sum, item) => sum + item.durationMinutes,
      ),
      activeDays: activeDays.length,
      weightChangeKg: rangeWeights.length < 2
          ? null
          : rangeWeights.last.weightKg - rangeWeights.first.weightKg,
      frequentFoods: frequent.take(5).toList(growable: false),
    );
  }

  static int _average(Iterable<num> values) {
    if (values.isEmpty) return 0;
    return (values.fold<double>(0, (sum, value) => sum + value) / values.length)
        .round();
  }

  static DateTime _day(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _inside(DateTime value, DateTime start, DateTime end) {
    final local = value.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }
}
