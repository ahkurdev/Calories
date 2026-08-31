import 'package:caloris/features/food/domain/food_models.dart';

abstract interface class FoodRepository {
  Future<List<FoodLog>> listForDay(DateTime day);
  Future<FoodLog> add(FoodLog food);
  Future<void> delete(String id);
  Future<List<FavoriteMeal>> listFavorites();
  Future<FavoriteMeal> saveFavorite(FavoriteMeal meal);
  Future<void> deleteFavorite(String id);
}
