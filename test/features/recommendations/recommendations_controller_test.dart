import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/recommendations/data/supabase_recommendation_repository.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/domain/recommendation_repository.dart';
import 'package:caloris/features/recommendations/presentation/controllers/recommendations_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'controller sends minimized meal context and exposes the result',
    () async {
      final repository = _FakeRecommendationRepository();
      final container = ProviderContainer(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final snapshot = HealthInsightsSnapshot(
        daily: DailyHealthStatistics(
          day: DateTime(2026, 9, 1),
          targetCalories: 1900,
          consumedCalories: 1350,
          waterMl: 1500,
          waterTargetMl: 2000,
          activityMinutes: 20,
          estimatedActivityCalories: 80,
        ),
        weekly: WeeklyHealthStatistics(
          start: DateTime(2026, 8, 26),
          endExclusive: DateTime(2026, 9, 2),
          targetCalories: 1900,
          averageCaloriesOnTrackedDays: 1700,
          calorieTrackingDays: 6,
          averageWaterOnTrackedDays: 1800,
          waterTrackingDays: 6,
          totalActivityMinutes: 90,
          activeDays: 4,
          frequentFoods: const ['Nasi'],
        ),
        goal: HealthGoal.loseWeight,
        foodHistory: [
          FoodLog(
            id: 'private-id',
            userId: 'private-user',
            mealType: MealType.lunch,
            foodName: 'Nasi',
            amount: 1,
            unit: PortionUnit.portion,
            calories: 250,
            loggedAt: DateTime(2026, 9, 1, 12),
          ),
        ],
        schedules: const [],
      );

      await container
          .read(recommendationsControllerProvider.notifier)
          .recommendMeal(
            snapshot,
            mealType: MealType.dinner,
            preference: 'sayur',
            practicalMode: true,
          );

      expect(repository.mealRequest?.remainingCalories, 550);
      expect(repository.mealRequest?.foodHistory.single.name, 'Nasi');
      expect(
        container
            .read(recommendationsControllerProvider)
            .results[RecommendationKind.meal]
            ?.message,
        contains('ayam bakar'),
      );
    },
  );
}

class _FakeRecommendationRepository implements RecommendationRepository {
  MealRecommendationRequest? mealRequest;

  @override
  Future<RecommendationResult> recommendMeal(
    MealRecommendationRequest request,
  ) async {
    mealRequest = request;
    return const RecommendationResult(
      status: RecommendationStatus.success,
      message: 'Coba ayam bakar, nasi setengah, dan sayur.',
    );
  }

  @override
  Future<RecommendationResult> generateDailySummary(
    DailyHealthStatistics statistics,
  ) async => const RecommendationResult.manualFallback();

  @override
  Future<RecommendationResult> generateWeeklySummary(
    WeeklyHealthStatistics statistics,
  ) async => const RecommendationResult.manualFallback();

  @override
  Future<RecommendationResult> recommendActivity(
    ActivityRecommendationRequest request,
  ) async => const RecommendationResult.manualFallback();
}
