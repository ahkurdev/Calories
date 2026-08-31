import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserProfile validProfile() => UserProfile(
    id: 'user-id',
    name: 'Alya',
    gender: Gender.female,
    birthDate: DateTime(DateTime.now().year - 25),
    heightCm: 165,
    currentWeightKg: 68.5,
    targetWeightKg: 60,
    activityLevel: ActivityLevel.lightlyActive,
    goal: HealthGoal.loseWeight,
  );

  group('UserProfile', () {
    test('serializes to the database contract', () {
      final json = validProfile().toJson();

      expect(json['gender'], 'female');
      expect(json['activity_level'], 'lightly_active');
      expect(json['goal'], 'lose_weight');
      expect(json['birth_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('rejects unrealistic height', () {
      final invalid = UserProfile(
        id: 'user-id',
        name: 'Alya',
        gender: Gender.female,
        birthDate: DateTime(DateTime.now().year - 25),
        heightCm: 80,
        currentWeightKg: 68.5,
        targetWeightKg: 60,
        activityLevel: ActivityLevel.lightlyActive,
        goal: HealthGoal.loseWeight,
      );

      expect(invalid.validate, throwsA(isA<ValidationFailure>()));
    });
  });
}
