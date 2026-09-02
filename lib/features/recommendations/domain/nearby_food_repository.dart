import 'package:caloris/features/recommendations/domain/recommendation_models.dart';

abstract interface class NearbyFoodRepository {
  Future<NearbyFoodSearchResult> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  });
}
