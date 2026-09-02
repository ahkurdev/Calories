import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/features/recommendations/domain/nearby_food_repository.dart';
import 'package:caloris/features/recommendations/domain/recommendation_models.dart';
import 'package:caloris/features/recommendations/services/nearby_food_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final nearbyFoodRepositoryProvider = Provider<NearbyFoodRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableNearbyFoodRepository();
  return SupabaseNearbyFoodRepository(Supabase.instance.client);
});

class SupabaseNearbyFoodRepository implements NearbyFoodRepository {
  const SupabaseNearbyFoodRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<NearbyFoodSearchResult> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'nearby-food',
        body: {
          'input': {
            'latitude': latitude,
            'longitude': longitude,
            'radiusMeters': radiusMeters.clamp(300, 3000),
          },
        },
      );
      final data = response.data;
      if (data is Map) {
        return NearbyFoodParser.parse(Map<String, Object?>.from(data));
      }
    } on FunctionException catch (error) {
      if (error.details is Map) {
        return NearbyFoodParser.parse(
          Map<String, Object?>.from(error.details as Map),
        );
      }
    } on Object {
      // The safe unavailable result below is shown to the user.
    }
    return const NearbyFoodSearchResult(
      status: NearbyFoodStatus.unavailable,
      message: 'Tempat makan sekitar belum dapat dimuat. Kamu dapat membuka Google Maps.',
    );
  }
}

class UnavailableNearbyFoodRepository implements NearbyFoodRepository {
  const UnavailableNearbyFoodRepository();

  @override
  Future<NearbyFoodSearchResult> search({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async => const NearbyFoodSearchResult(
    status: NearbyFoodStatus.configurationRequired,
    message: 'Pencarian tempat sekitar belum dikonfigurasi. Kamu dapat membuka Google Maps.',
  );
}
