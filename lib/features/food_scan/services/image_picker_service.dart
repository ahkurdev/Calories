import 'package:caloris/features/food_scan/domain/food_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final foodImageSelectionServiceProvider = Provider<FoodImageSelectionService>(
  (_) => ImagePickerFoodImageService(ImagePicker()),
);

class ImagePickerFoodImageService implements FoodImageSelectionService {
  const ImagePickerFoodImageService(this._picker);

  final ImagePicker _picker;

  @override
  Future<SelectedFoodImage?> select(FoodImageSource source) async {
    final image = await _picker.pickImage(
      source: source == FoodImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
      requestFullMetadata: false,
    );
    return image == null ? null : _toSelected(image);
  }

  @override
  Future<SelectedFoodImage?> recoverLost() async {
    final lost = await _picker.retrieveLostData();
    final image = lost.files?.firstOrNull;
    return image == null ? null : _toSelected(image);
  }

  SelectedFoodImage _toSelected(XFile file) => SelectedFoodImage(
    path: file.path,
    mimeType: file.mimeType ?? _mimeFromPath(file.path),
  );

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
