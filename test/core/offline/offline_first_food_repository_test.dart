import 'dart:io';

import 'package:caloris/core/offline/offline_first_food_repository.dart';
import 'package:caloris/core/offline/offline_store.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/domain/food_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'offline add is cached and syncs once with the same client UUID',
    () async {
      final remote = _FakeRemoteFoodRepository()..online = false;
      final store = _MemoryOfflineStore();
      final repository = OfflineFirstFoodRepository(
        remote,
        store,
        () => 'user-1',
        idFactory: () => '11111111-1111-4111-8111-111111111111',
      );
      final day = DateTime(2026, 9, 1);
      final food = FoodLog(
        id: '',
        userId: '',
        mealType: MealType.dinner,
        foodName: 'Ayam bakar',
        amount: 1,
        unit: PortionUnit.portion,
        calories: 320,
        loggedAt: DateTime(2026, 9, 1, 18),
      );

      final savedOffline = await repository.add(food);
      final cached = await repository.listForDay(day);

      expect(savedOffline.id, '11111111-1111-4111-8111-111111111111');
      expect(cached.single.foodName, 'Ayam bakar');
      expect(store.items, hasLength(1));

      remote.online = true;
      await repository.listForDay(day);
      await repository.listForDay(day);

      expect(remote.savedIds, ['11111111-1111-4111-8111-111111111111']);
      expect(store.items, isEmpty);
    },
  );
}

class _FakeRemoteFoodRepository implements FoodRepository {
  bool online = true;
  final List<FoodLog> records = [];
  final List<String> savedIds = [];

  void _requireOnline() {
    if (!online) throw const SocketException('offline');
  }

  @override
  Future<FoodLog> add(FoodLog food) async {
    _requireOnline();
    savedIds.add(food.id);
    records.removeWhere((item) => item.id == food.id);
    records.add(food);
    return food;
  }

  @override
  Future<void> delete(String id) async {
    _requireOnline();
    records.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<FoodLog>> listForDay(DateTime day) async {
    _requireOnline();
    return records
        .where((item) {
          final date = item.loggedAt.toLocal();
          return date.year == day.year &&
              date.month == day.month &&
              date.day == day.day;
        })
        .toList(growable: false);
  }

  @override
  Future<void> deleteFavorite(String id) async => _requireOnline();

  @override
  Future<List<FavoriteMeal>> listFavorites() async {
    _requireOnline();
    return const [];
  }

  @override
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal) async {
    _requireOnline();
    return meal;
  }
}

class _MemoryOfflineStore implements OfflineStore {
  final cache = <String, String>{};
  final items = <String, OutboxMutation>{};

  String _key(String ownerId, String cacheKey) => '$ownerId:$cacheKey';

  @override
  Future<void> writeCache({
    required String ownerId,
    required String cacheKey,
    required String payload,
  }) async => cache[_key(ownerId, cacheKey)] = payload;

  @override
  Future<String?> readCache({
    required String ownerId,
    required String cacheKey,
  }) async => cache[_key(ownerId, cacheKey)];

  @override
  Future<void> removeRecordFromCaches({
    required String ownerId,
    required String cachePrefix,
    required String recordId,
  }) async {}

  @override
  Future<void> enqueue(OutboxMutation mutation) async {
    items[mutation.id] = mutation;
  }

  @override
  Future<List<OutboxMutation>> pending({
    required String ownerId,
    required String entity,
    int limit = 20,
  }) async => items.values
      .where((item) => item.ownerId == ownerId && item.entity == entity)
      .take(limit)
      .toList(growable: false);

  @override
  Future<void> removeMutation(String id) async => items.remove(id);

  @override
  Future<void> incrementAttempt(String id) async {
    final item = items[id];
    if (item != null) items[id] = item.copyWith(attempts: item.attempts + 1);
  }

  @override
  Future<void> clearOwner(String ownerId) async {
    cache.removeWhere((key, _) => key.startsWith('$ownerId:'));
    items.removeWhere((_, item) => item.ownerId == ownerId);
  }
}
