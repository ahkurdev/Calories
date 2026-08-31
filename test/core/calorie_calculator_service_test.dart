import 'package:caloris/core/services/calorie_calculator_service.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CalorieCalculatorService();

  test('calculates BMI from metric height and weight', () {
    final result = service.calculate(
      gender: Gender.male,
      age: 30,
      heightCm: 180,
      weightKg: 81,
      activityLevel: ActivityLevel.sedentary,
      goal: HealthGoal.maintainWeight,
    );

    expect(result.bmi, closeTo(25, 0.01));
  });

  test('uses Mifflin-St Jeor BMR and activity multiplier', () {
    final result = service.calculate(
      gender: Gender.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activityLevel: ActivityLevel.moderatelyActive,
      goal: HealthGoal.maintainWeight,
    );

    expect(result.bmr, closeTo(1780, 0.01));
    expect(result.tdee, closeTo(2759, 0.01));
    expect(result.targetCalories, 2759);
  });

  test('applies a moderate loss deficit without crossing safety floor', () {
    final result = service.calculate(
      gender: Gender.female,
      age: 60,
      heightCm: 160,
      weightKg: 60,
      activityLevel: ActivityLevel.sedentary,
      goal: HealthGoal.loseWeight,
    );

    expect(result.targetCalories, 1200);
    expect(result.targetCalories, lessThanOrEqualTo(result.tdee.round()));
  });

  test('uses a neutral equation constant when gender is undisclosed', () {
    final result = service.calculate(
      gender: Gender.preferNotToSay,
      age: 30,
      heightCm: 170,
      weightKg: 70,
      activityLevel: ActivityLevel.lightlyActive,
      goal: HealthGoal.gainWeight,
    );

    expect(result.bmr, closeTo(1534.5, 0.01));
    expect(result.targetCalories, result.tdee.round() + 300);
  });
}
