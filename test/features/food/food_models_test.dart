import 'package:caloris/features/food/domain/food_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DailyFoodSummary totals calories and macronutrients', () {
    final logs = [
      FoodLog(
        id: '1',
        userId: 'user',
        mealType: MealType.breakfast,
        foodName: 'Oatmeal',
        amount: 1,
        unit: PortionUnit.bowl,
        calories: 300,
        protein: 12,
        carbohydrate: 50,
        fat: 7,
        fiber: 8,
        loggedAt: DateTime(2026, 9, 1, 8),
      ),
      FoodLog(
        id: '2',
        userId: 'user',
        mealType: MealType.lunch,
        foodName: 'Ayam dan nasi',
        amount: 1,
        unit: PortionUnit.portion,
        calories: 550,
        protein: 35,
        carbohydrate: 65,
        fat: 15,
        fiber: 4,
        loggedAt: DateTime(2026, 9, 1, 12),
      ),
    ];

    final summary = DailyFoodSummary.fromLogs(logs, targetCalories: 1900);

    expect(summary.consumedCalories, 850);
    expect(summary.remainingCalories, 1050);
    expect(summary.protein, 47);
    expect(summary.carbohydrate, 115);
    expect(summary.fat, 22);
    expect(summary.fiber, 12);
  });

  test('remaining calories never becomes negative for display', () {
    final summary = DailyFoodSummary.fromLogs([
      FoodLog(
        id: '1',
        userId: 'user',
        mealType: MealType.dinner,
        foodName: 'Dinner',
        amount: 1,
        unit: PortionUnit.portion,
        calories: 2100,
        loggedAt: DateTime(2026, 9, 1, 19),
      ),
    ], targetCalories: 1900);

    expect(summary.remainingCalories, 0);
    expect(summary.overTargetCalories, 200);
  });

  test(
    'FoodLog maps all database values without losing optional nutrition',
    () {
      final food = FoodLog.fromJson({
        'id': 'food-id',
        'user_id': 'user-id',
        'meal_type': 'snack',
        'food_name': 'Pisang',
        'amount': 1,
        'unit': 'fruit',
        'calories': 105,
        'protein': 1.3,
        'carbohydrate': 27,
        'fat': 0.4,
        'fiber': 3.1,
        'cooking_method': null,
        'logged_at': '2026-09-01T09:00:00.000Z',
      });

      expect(food.mealType, MealType.snack);
      expect(food.unit, PortionUnit.fruit);
      expect(food.fiber, 3.1);
      expect(food.toInsertJson('user-id')['food_name'], 'Pisang');
    },
  );
}
