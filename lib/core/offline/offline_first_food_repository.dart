import 'dart:convert';

import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/core/offline/client_uuid.dart';
import 'package:caloris/core/offline/offline_store.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/domain/food_repository.dart';

class OfflineFirstFoodRepository implements FoodRepository {
  OfflineFirstFoodRepository(
    this._remote,
    this._store,
    this._currentUserId, {
    String Function()? idFactory,
  }) : _idFactory = idFactory ?? ClientUuid.generate;

  static const _entity = 'food_logs';
  static const _cachePrefix = 'food-day:';

  final FoodRepository _remote;
  final OfflineStore _store;
  final String? Function() _currentUserId;
  final String Function() _idFactory;

  @override
  Future<List<FoodLog>> listForDay(DateTime day) async {
    final ownerId = _requireUserId();
    await _syncPending(ownerId);
    try {
      final logs = await _remote.listForDay(day);
      await _writeDay(ownerId, day, logs);
      return logs;
    } on Object catch (error) {
      final cached = await _readDay(ownerId, day);
      if (cached != null) return cached;
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  @override
  Future<FoodLog> add(FoodLog food) async {
    final ownerId = _requireUserId();
    final owned = food.copyWith(
      id: food.id.isEmpty ? _idFactory() : food.id,
      userId: ownerId,
    );
    try {
      await _syncPending(ownerId);
      final saved = await _remote.add(owned);
      await _upsertCached(ownerId, saved);
      return saved;
    } on AppFailure {
      rethrow;
    } on Object {
      await _store.enqueue(
        OutboxMutation(
          id: owned.id,
          ownerId: ownerId,
          entity: _entity,
          operation: 'upsert',
          payload: owned.toCacheJson(),
          createdAt: DateTime.now(),
        ),
      );
      await _upsertCached(ownerId, owned);
      return owned;
    }
  }

  @override
  Future<void> delete(String id) async {
    final ownerId = _requireUserId();
    try {
      await _syncPending(ownerId);
      await _remote.delete(id);
    } on AppFailure {
      rethrow;
    } on Object {
      await _store.enqueue(
        OutboxMutation(
          id: 'delete-$id',
          ownerId: ownerId,
          entity: _entity,
          operation: 'delete',
          payload: {'id': id},
          createdAt: DateTime.now(),
        ),
      );
    }
    await _store.removeRecordFromCaches(
      ownerId: ownerId,
      cachePrefix: _cachePrefix,
      recordId: id,
    );
  }

  @override
  Future<List<FavoriteMeal>> listFavorites() => _remote.listFavorites();

  @override
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal) =>
      _remote.saveFavorite(meal);

  @override
  Future<void> deleteFavorite(String id) => _remote.deleteFavorite(id);

  Future<void> _syncPending(String ownerId) async {
    final pending = await _store.pending(ownerId: ownerId, entity: _entity);
    for (final mutation in pending) {
      try {
        if (mutation.operation == 'upsert') {
          await _remote.add(FoodLog.fromJson(mutation.payload));
        } else if (mutation.operation == 'delete') {
          await _remote.delete(mutation.payload['id']! as String);
        }
        await _store.removeMutation(mutation.id);
      } on Object {
        await _store.incrementAttempt(mutation.id);
        break;
      }
    }
  }

  Future<void> _upsertCached(String ownerId, FoodLog food) async {
    final existing = await _readDay(ownerId, food.loggedAt) ?? <FoodLog>[];
    final updated = existing.where((item) => item.id != food.id).toList()
      ..add(food)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    await _writeDay(ownerId, food.loggedAt, updated);
  }

  Future<void> _writeDay(String ownerId, DateTime day, List<FoodLog> logs) =>
      _store.writeCache(
        ownerId: ownerId,
        cacheKey: _cacheKey(day),
        payload: jsonEncode(logs.map((item) => item.toCacheJson()).toList()),
      );

  Future<List<FoodLog>?> _readDay(String ownerId, DateTime day) async {
    final payload = await _store.readCache(
      ownerId: ownerId,
      cacheKey: _cacheKey(day),
    );
    if (payload == null) return null;
    try {
      final values = jsonDecode(payload) as List<Object?>;
      return values
          .map((item) => FoodLog.fromJson(item! as Map<String, Object?>))
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  String _requireUserId() {
    final id = _currentUserId();
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }

  static String _cacheKey(DateTime value) {
    final day = value.toLocal();
    return '$_cachePrefix${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }
}
