import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/progress/data/supabase_progress_repository.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weightLogsProvider = FutureProvider<List<WeightLog>>(
  (ref) => ref.watch(progressRepositoryProvider).listWeights(),
);

final todayWaterLogsProvider = FutureProvider<List<WaterLog>>(
  (ref) =>
      ref.watch(progressRepositoryProvider).listWaterForDay(DateTime.now()),
);

final todayActivitiesProvider = FutureProvider<List<ActivityLog>>(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .listActivitiesForDay(DateTime.now()),
);

final todayWaterSummaryProvider = Provider<AsyncValue<WaterSummary>>((ref) {
  final profile = ref.watch(profileControllerProvider).value;
  return ref
      .watch(todayWaterLogsProvider)
      .whenData(
        (logs) => WaterSummary(
          consumedMl: logs.fold(0, (total, log) => total + log.amountMl),
          targetMl: profile?.waterTargetMl ?? 2000,
        ),
      );
});

class ProgressActions {
  const ProgressActions(this.ref);

  final Ref ref;

  Future<void> addWeight(double weightKg, String? note) async {
    await ref
        .read(progressRepositoryProvider)
        .addWeight(
          WeightLog(
            id: '',
            userId: '',
            weightKg: weightKg,
            note: note,
            loggedAt: DateTime.now(),
          ),
        );
    ref.invalidate(weightLogsProvider);
    ref.invalidate(profileControllerProvider);
  }

  Future<void> addWater(int amountMl) async {
    await ref
        .read(progressRepositoryProvider)
        .addWater(
          WaterLog(
            id: '',
            userId: '',
            amountMl: amountMl,
            loggedAt: DateTime.now(),
          ),
        );
    ref.invalidate(todayWaterLogsProvider);
  }

  Future<void> addActivity({
    required String type,
    required int durationMinutes,
    double? distanceKm,
    double? estimatedCalories,
  }) async {
    await ref
        .read(progressRepositoryProvider)
        .addActivity(
          ActivityLog(
            id: '',
            userId: '',
            activityType: type,
            durationMinutes: durationMinutes,
            distanceKm: distanceKm,
            estimatedCalories: estimatedCalories,
            loggedAt: DateTime.now(),
          ),
        );
    ref.invalidate(todayActivitiesProvider);
  }
}

final progressActionsProvider = Provider(ProgressActions.new);
