import 'package:caloris/features/food/data/supabase_food_repository.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/domain/food_repository.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyFromYesterday preserves meal time on the selected day', () async {
    final repository = _FakeFoodRepository(
      logsByDay: {
        DateTime(2026, 8, 31): [
          FoodLog(
            id: 'old',
            userId: 'user',
            mealType: MealType.breakfast,
            foodName: 'Oatmeal',
            amount: 1,
            unit: PortionUnit.bowl,
            calories: 300,
            loggedAt: DateTime(2026, 8, 31, 7, 30),
          ),
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [foodRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(selectedDiaryDateProvider.notifier)
        .select(DateTime(2026, 9, 1));
    await container.read(foodDiaryControllerProvider.future);

    final count = await container
        .read(foodDiaryControllerProvider.notifier)
        .copyFromYesterday();

    expect(count, 1);
    expect(repository.added.single.loggedAt, DateTime(2026, 9, 1, 7, 30));
    expect(repository.added.single.id, isEmpty);
  });
}

class _FakeFoodRepository implements FoodRepository {
  _FakeFoodRepository({required this.logsByDay});

  final Map<DateTime, List<FoodLog>> logsByDay;
  final List<FoodLog> added = [];

  @override
  Future<FoodLog> add(FoodLog food) async {
    added.add(food);
    return food.copyWith(id: 'new-id', userId: 'user');
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteFavorite(String id) async {}

  @override
  Future<List<FoodLog>> listForDay(DateTime day) async =>
      logsByDay[DateTime(day.year, day.month, day.day)] ?? const [];

  @override
  Future<List<FavoriteMeal>> listFavorites() async => const [];

  @override
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal) async => meal;
}
