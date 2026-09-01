import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/recommendations/domain/insights_repository.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableInsightsRepository();
  return SupabaseInsightsRepository(Supabase.instance.client);
});

class SupabaseInsightsRepository implements InsightsRepository {
  const SupabaseInsightsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<InsightsDataset> loadRange({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final startIso = start.toUtc().toIso8601String();
    final endIso = endExclusive.toUtc().toIso8601String();
    try {
      final rows = await Future.wait([
        _range('food_logs', startIso, endIso),
        _range('water_logs', startIso, endIso),
        _range('activities', startIso, endIso),
        _range('weight_logs', startIso, endIso),
        _client
            .from('schedules')
            .select()
            .order('day_of_week')
            .order('start_time'),
      ]);
      return InsightsDataset(
        foods: rows[0].map(FoodLog.fromJson).toList(growable: false),
        water: rows[1].map(WaterLog.fromJson).toList(growable: false),
        activities: rows[2].map(ActivityLog.fromJson).toList(growable: false),
        weights: rows[3].map(WeightLog.fromJson).toList(growable: false),
        schedules: rows[4].map(ScheduleEntry.fromJson).toList(growable: false),
      );
    } on PostgrestException catch (error) {
      throw DataFailure(
        error.code == '42501'
            ? 'Kamu tidak memiliki izin untuk data insight ini.'
            : 'Data insight belum dapat dimuat. Coba lagi.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _range(
    String table,
    String start,
    String end,
  ) => _client
      .from(table)
      .select()
      .gte('logged_at', start)
      .lt('logged_at', end)
      .order('logged_at');
}

class UnavailableInsightsRepository implements InsightsRepository {
  const UnavailableInsightsRepository();

  @override
  Future<InsightsDataset> loadRange({
    required DateTime start,
    required DateTime endExclusive,
  }) => Future.error(const ConfigurationFailure());
}
