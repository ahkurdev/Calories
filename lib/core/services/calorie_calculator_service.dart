import 'dart:math' as math;

import 'package:caloris/features/profile/domain/user_profile.dart';

class CalorieCalculation {
  const CalorieCalculation({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
  });

  final double bmi;
  final double bmr;
  final double tdee;
  final int targetCalories;
}

class CalorieCalculatorService {
  const CalorieCalculatorService();

  CalorieCalculation calculate({
    required Gender gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required HealthGoal goal,
  }) {
    final heightMeters = heightCm / 100;
    final bmi = weightKg / (heightMeters * heightMeters);
    final bmr =
        (10 * weightKg) +
        (6.25 * heightCm) -
        (5 * age) +
        _genderConstant(gender);
    final tdee = bmr * _activityMultiplier(activityLevel);

    final target = switch (goal) {
      HealthGoal.loseWeight => math.min(
        tdee,
        math.max(tdee - 500, _safetyFloor(gender)),
      ),
      HealthGoal.maintainWeight => tdee,
      HealthGoal.gainWeight => tdee + 300,
    };

    return CalorieCalculation(
      bmi: bmi,
      bmr: bmr,
      tdee: tdee,
      targetCalories: target.round(),
    );
  }

  double _activityMultiplier(ActivityLevel level) => switch (level) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.lightlyActive => 1.375,
    ActivityLevel.moderatelyActive => 1.55,
    ActivityLevel.veryActive => 1.725,
  };

  double _genderConstant(Gender gender) => switch (gender) {
    Gender.male => 5,
    Gender.female => -161,
    Gender.other || Gender.preferNotToSay => -78,
  };

  double _safetyFloor(Gender gender) => switch (gender) {
    Gender.female => 1200,
    Gender.male => 1500,
    Gender.other || Gender.preferNotToSay => 1300,
  };
}
