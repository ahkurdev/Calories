import 'package:caloris/features/walking/domain/walking_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts only step deltas detected at walking speed', () {
    const service = WalkingFilterService();
    var state = const WalkingFilterState();

    state = service.acceptStepEvent(
      state,
      rawSteps: 1000,
      pedestrianWalking: true,
      speedMetersPerSecond: 1.2,
    );
    state = service.acceptStepEvent(
      state,
      rawSteps: 1012,
      pedestrianWalking: true,
      speedMetersPerSecond: 1.4,
    );

    expect(state.acceptedSteps, 12);
  });

  test('rejects steps while stopped or moving at vehicle speed', () {
    const service = WalkingFilterService();
    var state = const WalkingFilterState(lastRawSteps: 500, acceptedSteps: 8);

    state = service.acceptStepEvent(
      state,
      rawSteps: 510,
      pedestrianWalking: false,
      speedMetersPerSecond: 0,
    );
    state = service.acceptStepEvent(
      state,
      rawSteps: 520,
      pedestrianWalking: true,
      speedMetersPerSecond: 8,
    );

    expect(state.acceptedSteps, 8);
    expect(state.lastRawSteps, 520);
  });

  test('handles sensor resets and estimates calories by body weight', () {
    const service = WalkingFilterService();
    final reset = service.acceptStepEvent(
      const WalkingFilterState(lastRawSteps: 2000, acceptedSteps: 100),
      rawSteps: 3,
      pedestrianWalking: true,
      speedMetersPerSecond: 1,
    );

    expect(reset.acceptedSteps, 100);
    expect(
      service.estimatedCalories(steps: 1000, weightKg: 70),
      closeTo(40, 0.1),
    );
  });
}
