import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/progress/domain/progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableProgressRepository();
  return SupabaseProgressRepository(Supabase.instance.client);
});

class SupabaseProgressRepository implements ProgressRepository {
  const SupabaseProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WeightLog>> listWeights() async {
    try {
      final rows = await _client
          .from('weight_logs')
          .select()
          .order('logged_at');
      return rows.map(WeightLog.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<WeightLog> addWeight(WeightLog log) async {
    final ownerId = _requireUserId();
    try {
      final data = await _client
          .from('weight_logs')
          .insert(log.toInsertJson(ownerId))
          .select()
          .single();
      await _client
          .from('profiles')
          .update({'current_weight_kg': log.weightKg})
          .eq('id', ownerId);
      return WeightLog.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<List<WaterLog>> listWaterForDay(DateTime day) async {
    try {
      final range = _dayRange(day);
      final rows = await _client
          .from('water_logs')
          .select()
          .gte('logged_at', range.$1)
          .lt('logged_at', range.$2)
          .order('logged_at');
      return rows.map(WaterLog.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<WaterLog> addWater(WaterLog log) async {
    final ownerId = _requireUserId();
    try {
      final data = await _client
          .from('water_logs')
          .insert(log.toInsertJson(ownerId))
          .select()
          .single();
      return WaterLog.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<List<ActivityLog>> listActivitiesForDay(DateTime day) async {
    try {
      final range = _dayRange(day);
      final rows = await _client
          .from('activities')
          .select()
          .gte('logged_at', range.$1)
          .lt('logged_at', range.$2)
          .order('logged_at');
      return rows.map(ActivityLog.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<ActivityLog> addActivity(ActivityLog log) async {
    final ownerId = _requireUserId();
    try {
      final data = await _client
          .from('activities')
          .insert(log.toInsertJson(ownerId))
          .select()
          .single();
      return ActivityLog.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }

  (String, String) _dayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day).toUtc();
    final end = DateTime(day.year, day.month, day.day + 1).toUtc();
    return (start.toIso8601String(), end.toIso8601String());
  }

  String _message(PostgrestException error) => error.code == '42501'
      ? 'Kamu tidak memiliki izin untuk data progress ini.'
      : 'Data progress belum dapat diproses. Coba lagi.';
}

class UnavailableProgressRepository implements ProgressRepository {
  const UnavailableProgressRepository();

  Future<T> _unavailable<T>() => Future<T>.error(const ConfigurationFailure());

  @override
  Future<ActivityLog> addActivity(ActivityLog log) => _unavailable();

  @override
  Future<WaterLog> addWater(WaterLog log) => _unavailable();

  @override
  Future<WeightLog> addWeight(WeightLog log) => _unavailable();

  @override
  Future<List<ActivityLog>> listActivitiesForDay(DateTime day) =>
      _unavailable();

  @override
  Future<List<WaterLog>> listWaterForDay(DateTime day) => _unavailable();

  @override
  Future<List<WeightLog>> listWeights() => _unavailable();
}
