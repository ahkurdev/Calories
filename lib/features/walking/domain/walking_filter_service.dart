class WalkingFilterState {
  const WalkingFilterState({this.lastRawSteps, this.acceptedSteps = 0});

  final int? lastRawSteps;
  final int acceptedSteps;
}

class WalkingFilterService {
  const WalkingFilterService();

  static const maximumWalkingSpeedMetersPerSecond = 2.8;

  WalkingFilterState acceptStepEvent(
    WalkingFilterState current, {
    required int rawSteps,
    required bool pedestrianWalking,
    required double speedMetersPerSecond,
  }) {
    final previous = current.lastRawSteps;
    final delta = previous == null || rawSteps < previous
        ? 0
        : rawSteps - previous;
    final walkingSpeed =
        speedMetersPerSecond >= 0 &&
        speedMetersPerSecond <= maximumWalkingSpeedMetersPerSecond;
    return WalkingFilterState(
      lastRawSteps: rawSteps,
      acceptedSteps:
          current.acceptedSteps +
          (pedestrianWalking && walkingSpeed ? delta : 0),
    );
  }

  double estimatedCalories({required int steps, required double weightKg}) {
    if (steps <= 0 || weightKg <= 0) return 0;
    return steps * weightKg * 0.0005714;
  }
}
