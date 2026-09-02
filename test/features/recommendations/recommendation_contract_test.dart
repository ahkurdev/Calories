import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/services/recommendation_function_parser.dart';
import 'package:caloris/features/schedule/domain/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('meal recommendation input contains only minimized health context', () {
    final request = MealRecommendationRequest(
      remainingCalories: 550,
      goal: HealthGoal.loseWeight,
      mealType: MealType.dinner,
      preference: 'tanpa santan',
      practicalMode: true,
      foodHistory: [
        FoodHistoryItem(name: 'Nasi', calories: 200, mealType: MealType.lunch),
      ],
      question: 'Apa yang boleh saya makan malam ini?',
      conversation: const [
        FoodConversationMessage(
          role: FoodConversationRole.user,
          content: 'Saya ingin makanan yang praktis.',
        ),
      ],
      preferredFoods: const ['ayam', 'sayur'],
      limitedFoods: const ['santan'],
      nearbyPlaces: const [
        NearbyFoodPlace(
          id: 'place-1',
          name: 'Warung Sehat',
          address: 'Jalan Contoh 1',
          mapsUri: 'https://maps.google.com/?cid=1',
          websiteUri: 'https://warung.example/menu',
          rating: 4.5,
          userRatingCount: 120,
          priceLevel: 'PRICE_LEVEL_MODERATE',
          openNow: true,
          delivery: true,
          takeout: true,
          dineIn: false,
        ),
      ],
    );

    final json = request.toInputJson();

    expect(json['goal'], 'lose_weight');
    expect(json['practicalMode'], isTrue);
    expect(json['question'], 'Apa yang boleh saya makan malam ini?');
    expect(json['preferredFoods'], ['ayam', 'sayur']);
    expect(json['limitedFoods'], ['santan']);
    expect(
      (json['nearbyPlaces'] as List<Object?>).single,
      isNot(contains('mapsUri')),
    );
    expect(json, isNot(contains('email')));
    expect(json, isNot(contains('userId')));
  });

  test('activity input filters schedules to the selected day', () {
    const request = ActivityRecommendationRequest(
      dayOfWeek: 2,
      schedules: [
        ScheduleEntry(
          id: 'private-id',
          userId: 'private-user',
          dayOfWeek: 2,
          activityName: 'Kerja',
          startTime: LocalTime(hour: 8, minute: 0),
          endTime: LocalTime(hour: 17, minute: 0),
          category: ScheduleCategory.work,
          busynessLevel: 3,
        ),
        ScheduleEntry(
          id: 'other-day',
          userId: 'private-user',
          dayOfWeek: 3,
          activityName: 'Kuliah',
          startTime: LocalTime(hour: 9, minute: 0),
          endTime: LocalTime(hour: 11, minute: 0),
          category: ScheduleCategory.study,
          busynessLevel: 2,
        ),
      ],
    );

    final json = request.toInputJson();
    final schedules = json['schedules']! as List<Object?>;

    expect(schedules, hasLength(1));
    expect(schedules.single, isNot(contains('id')));
    expect(schedules.single, isNot(contains('userId')));
  });

  test('function parser distinguishes AI output from manual fallback', () {
    final success = RecommendationFunctionParser.parse({
      'status': 'success',
      'summary': 'Catatanmu konsisten hari ini.',
    }, contentKey: 'summary');
    final fallback = RecommendationFunctionParser.parse({
      'status': 'manual_fallback',
      'message': 'AI belum tersedia.',
    }, contentKey: 'summary');

    expect(success.isAiGenerated, isTrue);
    expect(success.message, contains('konsisten'));
    expect(fallback.isAiGenerated, isFalse);
    expect(fallback.message, contains('belum tersedia'));
  });

  test('function parser maps food choices and foods to limit', () {
    final result = RecommendationFunctionParser.parse({
      'status': 'success',
      'recommendation': 'Pilih menu yang sesuai sisa kalorimu.',
      'foods_to_choose': [
        {
          'name': 'Ayam bakar',
          'reason': 'Protein praktis dengan tambahan sayur.',
        },
      ],
      'foods_to_limit': [
        {
          'name': 'Gorengan',
          'reason': 'Batasi porsinya karena kalorinya cepat bertambah.',
        },
      ],
      'disclaimer': 'Bukan pengganti nasihat medis.',
    }, contentKey: 'recommendation');

    expect(result.foodsToChoose.single.name, 'Ayam bakar');
    expect(result.foodsToLimit.single.name, 'Gorengan');
    expect(result.disclaimer, contains('medis'));
  });
}
