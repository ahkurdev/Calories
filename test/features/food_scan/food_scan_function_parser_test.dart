import 'package:caloris/features/food_scan/services/supabase_food_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('function parser maps a backend manual fallback honestly', () {
    final result = FoodScanFunctionParser.parse({
      'status': 'manual_fallback',
      'error': 'provider_unavailable',
      'message': 'Analisis AI sedang tidak tersedia.',
    });

    expect(result.foods, isEmpty);
    expect(result.notes, contains('tidak tersedia'));
    expect(result.isDevelopmentMock, isFalse);
  });
}
