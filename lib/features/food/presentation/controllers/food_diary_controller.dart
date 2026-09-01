import 'package:caloris/core/offline/sqlite_offline_store.dart';
import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/food/data/supabase_food_repository.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDiaryDateProvider =
    NotifierProvider<SelectedDiaryDateController, DateTime>(
      SelectedDiaryDateController.new,
    );

class SelectedDiaryDateController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime value) {
    state = DateTime(value.year, value.month, value.day);
  }
}

final foodDiaryControllerProvider =
    AsyncNotifierProvider<FoodDiaryController, List<FoodLog>>(
      FoodDiaryController.new,
    );

class FoodDiaryController extends AsyncNotifier<List<FoodLog>> {
  @override
  Future<List<FoodLog>> build() {
    ref.watch(selectedDiaryDateProvider);
    return _load();
  }

  Future<bool> add(FoodLog food) =>
      _mutate(() => ref.read(foodRepositoryProvider).add(food));

  Future<bool> delete(String id) =>
      _mutate(() => ref.read(foodRepositoryProvider).delete(id));

  Future<bool> addAgain(FoodLog food) {
    final selected = ref.read(selectedDiaryDateProvider);
    final now = DateTime.now();
    return add(
      food.copyWith(
        id: '',
        loggedAt: DateTime(
          selected.year,
          selected.month,
          selected.day,
          now.hour,
          now.minute,
        ),
      ),
    );
  }

  Future<int> copyFromYesterday() async {
    final selected = ref.read(selectedDiaryDateProvider);
    final sourceDay = selected.subtract(const Duration(days: 1));
    state = const AsyncLoading();
    try {
      final previous = await ref
          .read(foodRepositoryProvider)
          .listForDay(sourceDay);
      for (final food in previous) {
        final time = food.loggedAt.toLocal();
        await ref
            .read(foodRepositoryProvider)
            .add(
              food.copyWith(
                id: '',
                loggedAt: DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                  time.hour,
                  time.minute,
                ),
              ),
            );
      }
      state = AsyncData(await _load());
      ref.invalidate(pendingFoodMutationsProvider);
      return previous.length;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 0;
    }
  }

  Future<bool> addFavorite(FavoriteMeal meal, MealType mealType) async {
    final selected = ref.read(selectedDiaryDateProvider);
    final now = DateTime.now();
    state = const AsyncLoading();
    try {
      for (final item in meal.items) {
        await ref
            .read(foodRepositoryProvider)
            .add(
              item.toLog(
                userId: '',
                mealType: mealType,
                loggedAt: DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                  now.hour,
                  now.minute,
                ),
              ),
            );
      }
      state = AsyncData(await _load());
      ref.invalidate(pendingFoodMutationsProvider);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> _mutate(Future<Object?> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      ref.invalidate(todayFoodLogsProvider);
      state = AsyncData(await _load());
      ref.invalidate(pendingFoodMutationsProvider);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncValue<List<FoodLog>>.error(error, stackTrace);
      return false;
    }
  }

  Future<List<FoodLog>> _load() => ref
      .read(foodRepositoryProvider)
      .listForDay(ref.read(selectedDiaryDateProvider));
}

final favoriteMealsProvider = FutureProvider<List<FavoriteMeal>>(
  (ref) => ref.watch(foodRepositoryProvider).listFavorites(),
);

final todayFoodLogsProvider = FutureProvider<List<FoodLog>>(
  (ref) => ref.watch(foodRepositoryProvider).listForDay(DateTime.now()),
);

final pendingFoodMutationsProvider = FutureProvider<int>((ref) async {
  final ownerId = ref.watch(authControllerProvider).session.userId;
  if (ownerId == null) return 0;
  final pending = await ref
      .watch(offlineStoreProvider)
      .pending(ownerId: ownerId, entity: 'food_logs', limit: 100);
  return pending.length;
});
