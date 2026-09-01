import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';

abstract interface class RecommendationRepository {
  Future<RecommendationResult> recommendMeal(MealRecommendationRequest request);

  Future<RecommendationResult> recommendActivity(
    ActivityRecommendationRequest request,
  );

  Future<RecommendationResult> generateDailySummary(
    DailyHealthStatistics statistics,
  );

  Future<RecommendationResult> generateWeeklySummary(
    WeeklyHealthStatistics statistics,
  );
}
