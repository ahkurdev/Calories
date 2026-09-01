import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';

enum RecommendationStatus { success, manualFallback, outOfScope }

class RecommendationResult {
  const RecommendationResult({required this.status, required this.message});

  const RecommendationResult.manualFallback([String? message])
    : status = RecommendationStatus.manualFallback,
      message =
          message ??
          'Insight AI sedang tidak tersedia. Statistik dasarmu tetap dapat dilihat.';

  final RecommendationStatus status;
  final String message;

  bool get isAiGenerated => status == RecommendationStatus.success;
}

class FoodHistoryItem {
  const FoodHistoryItem({
    required this.name,
    required this.calories,
    required this.mealType,
  });

  factory FoodHistoryItem.fromLog(FoodLog log) => FoodHistoryItem(
    name: log.foodName,
    calories: log.calories,
    mealType: log.mealType,
  );

  final String name;
  final double calories;
  final MealType mealType;

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    'calories': calories,
    'mealType': mealType.databaseValue,
  };
}

class MealRecommendationRequest {
  const MealRecommendationRequest({
    required this.remainingCalories,
    required this.goal,
    required this.mealType,
    required this.preference,
    required this.practicalMode,
    required this.foodHistory,
  });

  final int remainingCalories;
  final HealthGoal goal;
  final MealType mealType;
  final String preference;
  final bool practicalMode;
  final List<FoodHistoryItem> foodHistory;

  Map<String, Object?> toInputJson() => {
    'remainingCalories': remainingCalories.clamp(0, 10000),
    'goal': goal.databaseValue,
    'mealType': mealType.databaseValue,
    'preference': preference.trim(),
    'foodHistory': foodHistory
        .take(30)
        .map((item) => item.toJson())
        .toList(growable: false),
    'practicalMode': practicalMode,
  };
}

class ActivityRecommendationRequest {
  const ActivityRecommendationRequest({
    required this.dayOfWeek,
    required this.schedules,
  });

  final int dayOfWeek;
  final List<ScheduleEntry> schedules;

  Map<String, Object?> toInputJson() => {
    'dayOfWeek': dayOfWeek,
    'schedules': schedules
        .where((entry) => entry.dayOfWeek == dayOfWeek)
        .take(30)
        .map(
          (entry) => {
            'activityName': entry.activityName,
            'dayOfWeek': entry.dayOfWeek,
            'startTime': entry.startTime.label,
            'endTime': entry.endTime.label,
            'category': entry.category.databaseValue,
            'busynessLevel': entry.busynessLevel,
          },
        )
        .toList(growable: false),
  };
}
