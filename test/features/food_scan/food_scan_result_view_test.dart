import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:caloris/features/food_scan/presentation/widgets/food_scan_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scan result always identifies estimates and development mock', (
    tester,
  ) async {
    const result = FoodScanResult(
      status: ScanStatus.success,
      foods: [
        ScannedFoodItem(
          id: 'food',
          name: 'Contoh makanan',
          amount: 100,
          unit: PortionUnit.gram,
          calories: 200,
          confidence: 0.5,
        ),
      ],
      notes: 'Data contoh.',
      isDevelopmentMock: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodScanResultView(
            result: result,
            onEdit: (_) {},
            onRemove: (_) {},
            onAdd: () {},
          ),
        ),
      ),
    );

    expect(find.text('Estimasi AI'), findsOneWidget);
    expect(find.textContaining('dapat berbeda'), findsOneWidget);
    expect(find.textContaining('MODE MOCK DEVELOPMENT'), findsOneWidget);
  });
}
