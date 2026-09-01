import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';

class InsightsDataset {
  const InsightsDataset({
    required this.foods,
    required this.water,
    required this.activities,
    required this.weights,
    required this.schedules,
  });

  final List<FoodLog> foods;
  final List<WaterLog> water;
  final List<ActivityLog> activities;
  final List<WeightLog> weights;
  final List<ScheduleEntry> schedules;
}

abstract interface class InsightsRepository {
  Future<InsightsDataset> loadRange({
    required DateTime start,
    required DateTime endExclusive,
  });
}
