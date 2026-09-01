import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:caloris/features/recommendations/services/health_statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = HealthStatisticsService();

  test('daily statistics are calculated before an AI summary is requested', () {
    final day = DateTime(2026, 9, 1);
    final stats = service.daily(
      day: day,
      targetCalories: 1900,
      waterTargetMl: 2000,
      foods: [
        _food('Nasi', 450, DateTime(2026, 9, 1, 12)),
        _food('Ayam', 300, DateTime(2026, 9, 1, 12, 15)),
      ],
      water: [
        _water(500, DateTime(2026, 9, 1, 9)),
        _water(750, DateTime(2026, 9, 1, 15)),
      ],
      activities: [_activity(20, DateTime(2026, 9, 1, 17))],
    );

    expect(stats.consumedCalories, 750);
    expect(stats.remainingCalories, 1150);
    expect(stats.waterMl, 1250);
    expect(stats.activityMinutes, 20);
    expect(stats.toAiJson(), isNot(contains('email')));
  });

  test('weekly statistics use tracked-day averages and weight chronology', () {
    final stats = service.weekly(
      start: DateTime(2026, 8, 26),
      endExclusive: DateTime(2026, 9, 2),
      targetCalories: 1900,
      foods: [
        _food('Nasi', 1000, DateTime(2026, 8, 26, 12)),
        _food('Nasi', 1400, DateTime(2026, 8, 27, 12)),
        _food('Ikan', 400, DateTime(2026, 8, 27, 18)),
      ],
      water: [
        _water(1000, DateTime(2026, 8, 26, 10)),
        _water(2000, DateTime(2026, 8, 27, 10)),
      ],
      activities: [
        _activity(20, DateTime(2026, 8, 26, 17)),
        _activity(30, DateTime(2026, 8, 28, 17)),
      ],
      weights: [
        _weight(75, DateTime(2026, 8, 26, 7)),
        _weight(74.4, DateTime(2026, 9, 1, 7)),
      ],
    );

    expect(stats.averageCaloriesOnTrackedDays, 1400);
    expect(stats.calorieTrackingDays, 2);
    expect(stats.averageWaterOnTrackedDays, 1500);
    expect(stats.activeDays, 2);
    expect(stats.totalActivityMinutes, 50);
    expect(stats.weightChangeKg, closeTo(-0.6, 0.001));
    expect(stats.frequentFoods.first, 'Nasi');
  });
}

FoodLog _food(String name, double calories, DateTime loggedAt) => FoodLog(
  id: '$name-$loggedAt',
  userId: 'user',
  mealType: MealType.lunch,
  foodName: name,
  amount: 1,
  unit: PortionUnit.portion,
  calories: calories,
  loggedAt: loggedAt,
);

WaterLog _water(int amount, DateTime loggedAt) => WaterLog(
  id: '$amount-$loggedAt',
  userId: 'user',
  amountMl: amount,
  loggedAt: loggedAt,
);

ActivityLog _activity(int minutes, DateTime loggedAt) => ActivityLog(
  id: '$minutes-$loggedAt',
  userId: 'user',
  activityType: 'Jalan kaki',
  durationMinutes: minutes,
  loggedAt: loggedAt,
);

WeightLog _weight(double weight, DateTime loggedAt) => WeightLog(
  id: '$weight-$loggedAt',
  userId: 'user',
  weightKg: weight,
  loggedAt: loggedAt,
);
