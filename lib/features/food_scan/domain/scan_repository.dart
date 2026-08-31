import 'dart:typed_data';

import 'package:caloris/features/food_scan/domain/food_scan_models.dart';

abstract interface class ScanRepository {
  Future<List<ScanHistoryEntry>> listHistory();
  Future<ScanHistoryEntry> saveHistory(
    FoodScanResult result, {
    Uint8List? imageBytes,
    String? mimeType,
  });
}
