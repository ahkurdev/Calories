import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FoodScanResult parses the provider-neutral structured schema', () {
    final result = FoodScanResult.fromJson({
      'status': 'success',
      'foods': [
        {
          'name': 'Nasi putih',
          'estimated_grams': 150,
          'estimated_calories': 195,
          'confidence': 0.88,
          'unit': 'gram',
          'cooking_method': 'steamed',
        },
      ],
      'total_estimated_calories': 195,
      'notes': 'Perkiraan berdasarkan foto.',
    });

    expect(result.status, ScanStatus.success);
    expect(result.foods.single.name, 'Nasi putih');
    expect(result.foods.single.unit, PortionUnit.gram);
    expect(result.foods.single.confidence, 0.88);
  });

  test('FoodScanResult rejects confidence outside zero to one', () {
    final result = FoodScanResult(
      status: ScanStatus.success,
      foods: const [
        ScannedFoodItem(
          id: 'item',
          name: 'Makanan',
          amount: 100,
          unit: PortionUnit.gram,
          calories: 200,
          confidence: 1.5,
        ),
      ],
      notes: 'Test',
      isDevelopmentMock: false,
    );

    expect(result.validate, throwsA(isA<ArgumentError>()));
  });
}
