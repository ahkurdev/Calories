import 'dart:convert';
import 'dart:io';

import 'package:caloris/features/food_scan/domain/food_recognition_service.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFoodRecognitionService implements FoodRecognitionService {
  const SupabaseFoodRecognitionService(this._client);

  final SupabaseClient _client;

  @override
  Future<FoodScanResult> analyze({
    required String imagePath,
    required String mimeType,
  }) async {
    if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      return const FoodScanResult(
        status: ScanStatus.manualFallback,
        foods: [],
        notes:
            'Format foto belum didukung. Gunakan JPEG, PNG, atau WebP, '
            'atau masukkan makanan secara manual.',
        isDevelopmentMock: false,
      );
    }
    final file = File(imagePath);
    final size = await file.length();
    if (size <= 0 || size > 10 * 1024 * 1024) {
      return const FoodScanResult(
        status: ScanStatus.manualFallback,
        foods: [],
        notes:
            'Ukuran foto tidak valid atau melebihi 10 MB. '
            'Pilih foto lain atau gunakan input manual.',
        isDevelopmentMock: false,
      );
    }
    try {
      final bytes = await file.readAsBytes();
      final response = await _client.functions.invoke(
        'analyze-food',
        body: {
          'task': 'food_scan',
          'input': {
            'image': {'mimeType': mimeType, 'base64': base64Encode(bytes)},
          },
        },
      );
      final data = response.data;
      if (data is! Map) return FoodScanFunctionParser.invalidFallback;
      return FoodScanFunctionParser.parse(Map<String, Object?>.from(data));
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map) {
        return FoodScanFunctionParser.parse(Map<String, Object?>.from(details));
      }
      return FoodScanFunctionParser.invalidFallback;
    } on Object {
      return const FoodScanResult(
        status: ScanStatus.manualFallback,
        foods: [],
        notes:
            'Analisis AI sedang tidak tersedia. Kamu tetap dapat '
            'memasukkan makanan secara manual.',
        isDevelopmentMock: false,
      );
    }
  }
}

class FoodScanFunctionParser {
  const FoodScanFunctionParser._();

  static const invalidFallback = FoodScanResult(
    status: ScanStatus.manualFallback,
    foods: [],
    notes: 'Respons AI tidak valid. Gunakan input makanan manual.',
    isDevelopmentMock: false,
  );

  static FoodScanResult parse(Map<String, Object?> json) {
    final status = json['status'];
    if (status == 'manual_fallback' || status == 'error') {
      return FoodScanResult(
        status: ScanStatus.manualFallback,
        foods: const [],
        notes:
            (json['message'] as String?) ??
            'Analisis AI sedang tidak tersedia. Gunakan input manual.',
        isDevelopmentMock: false,
      );
    }
    if (status == 'out_of_scope') {
      return FoodScanResult(
        status: ScanStatus.manualFallback,
        foods: const [],
        notes:
            (json['message'] as String?) ??
            'Foto tidak dapat diproses sebagai makanan.',
        isDevelopmentMock: false,
      );
    }
    try {
      final result = FoodScanResult.fromJson(json);
      result.validate();
      return result;
    } on Object {
      return invalidFallback;
    }
  }
}
