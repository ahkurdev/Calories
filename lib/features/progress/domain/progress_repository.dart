import 'package:caloris/features/progress/domain/progress_models.dart';

abstract interface class ProgressRepository {
  Future<List<WeightLog>> listWeights();
  Future<WeightLog> addWeight(WeightLog log);
  Future<List<WaterLog>> listWaterForDay(DateTime day);
  Future<WaterLog> addWater(WaterLog log);
  Future<List<ActivityLog>> listActivitiesForDay(DateTime day);
  Future<ActivityLog> addActivity(ActivityLog log);
}
