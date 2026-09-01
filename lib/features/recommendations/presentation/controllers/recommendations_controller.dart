import 'package:caloris/core/services/calorie_calculator_service.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/recommendations/data/supabase_insights_repository.dart';
import 'package:caloris/features/recommendations/data/supabase_recommendation_repository.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/services/health_statistics_service.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HealthInsightsSnapshot {
  const HealthInsightsSnapshot({
    required this.daily,
    required this.weekly,
    required this.goal,
    required this.foodHistory,
    required this.schedules,
  });

  final DailyHealthStatistics daily;
  final WeeklyHealthStatistics weekly;
  final HealthGoal goal;
  final List<FoodLog> foodHistory;
  final List<ScheduleEntry> schedules;
}

final healthInsightsProvider = FutureProvider<HealthInsightsSnapshot>((
  ref,
) async {
  final profile = await ref.watch(profileControllerProvider.future);
  if (profile == null) throw StateError('Profil belum tersedia.');
  final calculation = const CalorieCalculatorService().calculate(
    gender: profile.gender,
    age: profile.age,
    heightCm: profile.heightCm,
    weightKg: profile.currentWeightKg,
    activityLevel: profile.activityLevel,
    goal: profile.goal,
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 6));
  final end = today.add(const Duration(days: 1));
  final data = await ref
      .watch(insightsRepositoryProvider)
      .loadRange(start: start, endExclusive: end);
  const statistics = HealthStatisticsService();
  return HealthInsightsSnapshot(
    daily: statistics.daily(
      day: today,
      targetCalories: calculation.targetCalories,
      waterTargetMl: profile.waterTargetMl,
      foods: data.foods,
      water: data.water,
      activities: data.activities,
    ),
    weekly: statistics.weekly(
      start: start,
      endExclusive: end,
      targetCalories: calculation.targetCalories,
      foods: data.foods,
      water: data.water,
      activities: data.activities,
      weights: data.weights,
    ),
    goal: profile.goal,
    foodHistory: data.foods,
    schedules: data.schedules,
  );
});

enum RecommendationKind { meal, activity, dailySummary, weeklySummary }

class RecommendationsState {
  const RecommendationsState({
    this.results = const {},
    this.loading = const {},
  });

  final Map<RecommendationKind, RecommendationResult> results;
  final Set<RecommendationKind> loading;

  RecommendationsState copyWith({
    Map<RecommendationKind, RecommendationResult>? results,
    Set<RecommendationKind>? loading,
  }) => RecommendationsState(
    results: results ?? this.results,
    loading: loading ?? this.loading,
  );
}

final recommendationsControllerProvider =
    NotifierProvider<RecommendationsController, RecommendationsState>(
      RecommendationsController.new,
    );

class RecommendationsController extends Notifier<RecommendationsState> {
  @override
  RecommendationsState build() => const RecommendationsState();

  Future<void> recommendMeal(
    HealthInsightsSnapshot snapshot, {
    required MealType mealType,
    required String preference,
    required bool practicalMode,
  }) {
    final history = snapshot.foodHistory.toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return _run(
      RecommendationKind.meal,
      () => ref
          .read(recommendationRepositoryProvider)
          .recommendMeal(
            MealRecommendationRequest(
              remainingCalories: snapshot.daily.remainingCalories,
              goal: snapshot.goal,
              mealType: mealType,
              preference: preference,
              practicalMode: practicalMode,
              foodHistory: history
                  .take(30)
                  .map(FoodHistoryItem.fromLog)
                  .toList(growable: false),
            ),
          ),
    );
  }

  Future<void> recommendActivity(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.activity,
    () => ref
        .read(recommendationRepositoryProvider)
        .recommendActivity(
          ActivityRecommendationRequest(
            dayOfWeek: snapshot.daily.day.weekday,
            schedules: snapshot.schedules,
          ),
        ),
  );

  Future<void> generateDailySummary(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.dailySummary,
    () => ref
        .read(recommendationRepositoryProvider)
        .generateDailySummary(snapshot.daily),
  );

  Future<void> generateWeeklySummary(HealthInsightsSnapshot snapshot) => _run(
    RecommendationKind.weeklySummary,
    () => ref
        .read(recommendationRepositoryProvider)
        .generateWeeklySummary(snapshot.weekly),
  );

  Future<void> _run(
    RecommendationKind kind,
    Future<RecommendationResult> Function() operation,
  ) async {
    state = state.copyWith(loading: {...state.loading, kind});
    RecommendationResult result;
    try {
      result = await operation();
    } on Object {
      result = const RecommendationResult.manualFallback();
    }
    final loading = {...state.loading}..remove(kind);
    state = state.copyWith(
      results: {...state.results, kind: result},
      loading: loading,
    );
  }
}
