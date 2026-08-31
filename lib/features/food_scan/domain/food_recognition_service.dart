import 'package:caloris/features/food_scan/domain/food_scan_models.dart';

abstract interface class FoodRecognitionService {
  Future<FoodScanResult> analyze({
    required String imagePath,
    required String mimeType,
  });
}

class SelectedFoodImage {
  const SelectedFoodImage({required this.path, required this.mimeType});

  final String path;
  final String mimeType;
}

enum FoodImageSource { camera, gallery }

abstract interface class FoodImageSelectionService {
  Future<SelectedFoodImage?> select(FoodImageSource source);
  Future<SelectedFoodImage?> recoverLost();
}
