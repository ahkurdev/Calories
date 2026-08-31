import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/features/food_scan/domain/food_recognition_service.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final foodRecognitionServiceProvider = Provider<FoodRecognitionService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return environment.useMockAi
      ? const MockFoodRecognitionService()
      : const UnavailableFoodRecognitionService();
});

class MockFoodRecognitionService implements FoodRecognitionService {
  const MockFoodRecognitionService();

  @override
  Future<FoodScanResult> analyze({
    required String imagePath,
    required String mimeType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return FoodScanResult.fromJson({
      'status': 'success',
      'foods': [
        {
          'name': 'Nasi putih (contoh mock)',
          'estimated_grams': 150,
          'estimated_calories': 195,
          'confidence': 0.65,
          'unit': 'gram',
          'cooking_method': 'steamed',
        },
        {
          'name': 'Lauk (contoh mock)',
          'estimated_grams': 100,
          'estimated_calories': 220,
          'confidence': 0.5,
          'unit': 'gram',
        },
      ],
      'notes': 'Data contoh development; bukan hasil analisis foto atau AI.',
    }, isDevelopmentMock: true);
  }
}

class UnavailableFoodRecognitionService implements FoodRecognitionService {
  const UnavailableFoodRecognitionService();

  @override
  Future<FoodScanResult> analyze({
    required String imagePath,
    required String mimeType,
  }) async => const FoodScanResult(
    status: ScanStatus.manualFallback,
    foods: [],
    notes:
        'Analisis AI belum dikonfigurasi. Tambahkan komponen secara manual, '
        'atau aktifkan mock khusus development.',
    isDevelopmentMock: false,
  );
}
