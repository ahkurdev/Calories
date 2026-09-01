import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/features/recommendations/domain/health_statistics.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/domain/recommendation_repository.dart';
import 'package:caloris/features/recommendations/services/recommendation_function_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) {
    return const UnavailableRecommendationRepository();
  }
  return SupabaseRecommendationRepository(Supabase.instance.client);
});

class SupabaseRecommendationRepository implements RecommendationRepository {
  const SupabaseRecommendationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<RecommendationResult> recommendMeal(
    MealRecommendationRequest request,
  ) => _invoke(
    functionName: 'recommend-meal',
    task: 'food_recommendation',
    input: request.toInputJson(),
    contentKey: 'recommendation',
  );

  @override
  Future<RecommendationResult> recommendActivity(
    ActivityRecommendationRequest request,
  ) => _invoke(
    functionName: 'recommend-activity',
    task: 'schedule_recommendation',
    input: request.toInputJson(),
    contentKey: 'recommendation',
  );

  @override
  Future<RecommendationResult> generateDailySummary(
    DailyHealthStatistics statistics,
  ) => _invoke(
    functionName: 'generate-daily-summary',
    task: 'daily_summary',
    input: {'stats': statistics.toAiJson()},
    contentKey: 'summary',
  );

  @override
  Future<RecommendationResult> generateWeeklySummary(
    WeeklyHealthStatistics statistics,
  ) => _invoke(
    functionName: 'generate-weekly-summary',
    task: 'weekly_summary',
    input: {'stats': statistics.toAiJson()},
    contentKey: 'summary',
  );

  Future<RecommendationResult> _invoke({
    required String functionName,
    required String task,
    required Map<String, Object?> input,
    required String contentKey,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: {'task': task, 'input': input},
      );
      final data = response.data;
      if (data is! Map) return const RecommendationResult.manualFallback();
      return RecommendationFunctionParser.parse(
        Map<String, Object?>.from(data),
        contentKey: contentKey,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        return RecommendationFunctionParser.parse(
          Map<String, Object?>.from(details),
          contentKey: contentKey,
        );
      }
      return const RecommendationResult.manualFallback();
    } on Object {
      return const RecommendationResult.manualFallback();
    }
  }
}

class UnavailableRecommendationRepository implements RecommendationRepository {
  const UnavailableRecommendationRepository();

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

  @override
  Future<RecommendationResult> recommendMeal(
    MealRecommendationRequest request,
  ) async => const RecommendationResult.manualFallback();
}
