import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/domain/food_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableFoodRepository();
  return SupabaseFoodRepository(Supabase.instance.client);
});

class SupabaseFoodRepository implements FoodRepository {
  const SupabaseFoodRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<FoodLog> add(FoodLog food) async {
    final ownerId = _requireUserId();
    try {
      final data = await _client
          .from('food_logs')
          .insert(food.toInsertJson(ownerId))
          .select()
          .single();
      return FoodLog.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('food_logs').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<List<FoodLog>> listForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).toUtc();
    final end = DateTime(day.year, day.month, day.day + 1).toUtc();
    try {
      final rows = await _client
          .from('food_logs')
          .select()
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', end.toIso8601String())
          .order('logged_at');
      return rows.map(FoodLog.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<List<FavoriteMeal>> listFavorites() async {
    try {
      final rows = await _client.from('favorite_meals').select().order('name');
      return rows.map(FavoriteMeal.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal) async {
    final ownerId = _requireUserId();
    try {
      final data = await _client
          .from('favorite_meals')
          .insert(meal.toInsertJson(ownerId))
          .select()
          .single();
      return FavoriteMeal.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<void> deleteFavorite(String id) async {
    try {
      await _client.from('favorite_meals').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }

  String _message(PostgrestException error) => error.code == '42501'
      ? 'Kamu tidak memiliki izin untuk catatan makanan ini.'
      : 'Catatan makanan belum dapat diproses. Coba lagi.';
}

class UnavailableFoodRepository implements FoodRepository {
  const UnavailableFoodRepository();

  Future<T> _unavailable<T>() => Future<T>.error(const ConfigurationFailure());

  @override
  Future<FoodLog> add(FoodLog food) => _unavailable();

  @override
  Future<void> delete(String id) => _unavailable();

  @override
  Future<void> deleteFavorite(String id) => _unavailable();

  @override
  Future<List<FoodLog>> listForDay(DateTime day) => _unavailable();

  @override
  Future<List<FavoriteMeal>> listFavorites() => _unavailable();

  @override
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal) => _unavailable();
}
