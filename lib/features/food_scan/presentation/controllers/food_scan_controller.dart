import 'dart:io';

import 'package:caloris/features/food/data/supabase_food_repository.dart';
import 'package:caloris/features/food/domain/food_models.dart';
import 'package:caloris/features/food/presentation/controllers/food_diary_controller.dart';
import 'package:caloris/features/food_scan/data/supabase_scan_repository.dart';
import 'package:caloris/features/food_scan/domain/food_recognition_service.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:caloris/features/food_scan/services/image_picker_service.dart';
import 'package:caloris/features/food_scan/services/mock_food_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoodScanState {
  const FoodScanState({
    this.image,
    this.result,
    this.isWorking = false,
    this.doNotStorePhoto = true,
    this.errorMessage,
  });

  final SelectedFoodImage? image;
  final FoodScanResult? result;
  final bool isWorking;
  final bool doNotStorePhoto;
  final String? errorMessage;

  FoodScanState copyWith({
    SelectedFoodImage? image,
    FoodScanResult? result,
    bool? isWorking,
    bool? doNotStorePhoto,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) => FoodScanState(
    image: image ?? this.image,
    result: clearResult ? null : result ?? this.result,
    isWorking: isWorking ?? this.isWorking,
    doNotStorePhoto: doNotStorePhoto ?? this.doNotStorePhoto,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

final foodScanControllerProvider =
    NotifierProvider.autoDispose<FoodScanController, FoodScanState>(
      FoodScanController.new,
    );

class FoodScanController extends Notifier<FoodScanState> {
  @override
  FoodScanState build() => const FoodScanState();

  Future<void> selectImage(FoodImageSource source) async {
    try {
      final image = await ref
          .read(foodImageSelectionServiceProvider)
          .select(source);
      if (image != null) {
        state = FoodScanState(
          image: image,
          doNotStorePhoto: state.doNotStorePhoto,
        );
      }
    } catch (_) {
      state = state.copyWith(
        errorMessage:
            'Foto belum dapat dibuka. Periksa izin kamera atau galeri.',
      );
    }
  }

  Future<void> recoverLostImage() async {
    if (state.image != null) return;
    try {
      final image = await ref
          .read(foodImageSelectionServiceProvider)
          .recoverLost();
      if (image != null) state = state.copyWith(image: image, clearError: true);
    } catch (_) {
      // Lost-data recovery is best effort and should not block a fresh scan.
    }
  }

  Future<void> analyze() async {
    final image = state.image;
    if (image == null) return;
    state = state.copyWith(
      isWorking: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final result = await ref
          .read(foodRecognitionServiceProvider)
          .analyze(imagePath: image.path, mimeType: image.mimeType);
      result.validate();
      state = state.copyWith(result: result, isWorking: false);
    } catch (_) {
      state = state.copyWith(
        isWorking: false,
        errorMessage:
            'Analisis makanan sedang tidak tersedia. Kamu tetap dapat '
            'menambahkan komponen secara manual.',
      );
    }
  }

  void setDoNotStorePhoto(bool value) {
    state = state.copyWith(doNotStorePhoto: value);
  }

  void updateItem(ScannedFoodItem item) {
    final result = state.result;
    if (result == null) return;
    state = state.copyWith(
      result: result.copyWith(
        foods: [
          for (final current in result.foods)
            if (current.id == item.id) item else current,
        ],
      ),
    );
  }

  void addItem() {
    final result =
        state.result ??
        const FoodScanResult(
          status: ScanStatus.manualFallback,
          foods: [],
          notes: 'Komponen ditambahkan secara manual.',
          isDevelopmentMock: false,
        );
    state = state.copyWith(
      result: result.copyWith(
        foods: [
          ...result.foods,
          ScannedFoodItem(
            id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
            name: 'Komponen makanan',
            amount: 100,
            unit: PortionUnit.gram,
            calories: 0,
            confidence: 0,
          ),
        ],
      ),
      clearError: true,
    );
  }

  void removeItem(String id) {
    final result = state.result;
    if (result == null) return;
    state = state.copyWith(
      result: result.copyWith(
        foods: result.foods
            .where((food) => food.id != id)
            .toList(growable: false),
      ),
    );
  }

  Future<bool> saveToDiary(MealType mealType) async {
    final result = state.result;
    final image = state.image;
    if (result == null || result.foods.isEmpty || image == null) return false;
    state = state.copyWith(isWorking: true, clearError: true);
    try {
      result.validate();
      final now = DateTime.now();
      for (final item in result.foods) {
        await ref
            .read(foodRepositoryProvider)
            .add(item.toFoodLog(mealType, now));
      }
      final bytes = state.doNotStorePhoto
          ? null
          : await File(image.path).readAsBytes();
      await ref
          .read(scanRepositoryProvider)
          .saveHistory(
            result,
            imageBytes: bytes,
            mimeType: bytes == null ? null : image.mimeType,
          );
      ref.invalidate(todayFoodLogsProvider);
      ref.invalidate(scanHistoryProvider);
      state = FoodScanState(doNotStorePhoto: state.doNotStorePhoto);
      return true;
    } catch (error) {
      state = state.copyWith(isWorking: false, errorMessage: '$error');
      return false;
    }
  }

  void reset() => state = FoodScanState(doNotStorePhoto: state.doNotStorePhoto);
}

final scanHistoryProvider = FutureProvider<List<ScanHistoryEntry>>(
  (ref) => ref.watch(scanRepositoryProvider).listHistory(),
);
