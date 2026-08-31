import 'package:caloris/core/services/calorie_calculator_service.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calorieCalculationProvider = Provider<CalorieCalculation?>((ref) {
  final profile = ref.watch(profileControllerProvider).value;
  if (profile == null) return null;
  return const CalorieCalculatorService().calculate(
    gender: profile.gender,
    age: profile.age,
    heightCm: profile.heightCm,
    weightKg: profile.currentWeightKg,
    activityLevel: profile.activityLevel,
    goal: profile.goal,
  );
});

final dailyFoodSummaryProvider = Provider<AsyncValue<DailyFoodSummary>>((ref) {
  final target = ref.watch(calorieCalculationProvider)?.targetCalories ?? 0;
  return ref
      .watch(todayFoodLogsProvider)
      .whenData(
        (logs) => DailyFoodSummary.fromLogs(logs, targetCalories: target),
      );
});
