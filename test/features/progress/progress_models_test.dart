import 'package:caloris/features/progress/domain/progress_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'WeightProgress describes a weight-loss journey without negative values',
    () {
      final progress = WeightProgress.calculate(
        startingWeightKg: 80,
        currentWeightKg: 74,
        targetWeightKg: 68,
      );

      expect(progress.totalChangeKg, -6);
      expect(progress.remainingKg, 6);
      expect(progress.progress, 0.5);
    },
  );

  test('WeightProgress also supports a weight-gain goal', () {
    final progress = WeightProgress.calculate(
      startingWeightKg: 55,
      currentWeightKg: 58,
      targetWeightKg: 61,
    );

    expect(progress.totalChangeKg, 3);
    expect(progress.remainingKg, 3);
    expect(progress.progress, 0.5);
  });

  test('WaterSummary clamps progress while retaining consumed amount', () {
    const summary = WaterSummary(consumedMl: 2500, targetMl: 2000);

    expect(summary.progress, 1);
    expect(summary.remainingMl, 0);
    expect(summary.consumedMl, 2500);
  });
}
