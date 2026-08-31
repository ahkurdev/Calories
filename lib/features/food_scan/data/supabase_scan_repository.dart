import 'dart:typed_data';

import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/food_scan/domain/food_scan_models.dart';
import 'package:caloris/features/food_scan/domain/scan_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableScanRepository();
  return SupabaseScanRepository(Supabase.instance.client);
});

class SupabaseScanRepository implements ScanRepository {
  const SupabaseScanRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ScanHistoryEntry>> listHistory() async {
    try {
      final rows = await _client
          .from('scan_history')
          .select()
          .order('scanned_at', ascending: false)
          .limit(50);
      return rows.map(ScanHistoryEntry.fromJson).toList(growable: false);
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }
  }

  @override
  Future<ScanHistoryEntry> saveHistory(
    FoodScanResult result, {
    Uint8List? imageBytes,
    String? mimeType,
  }) async {
    result.validate();
    final ownerId = _requireUserId();
    Map<String, Object?> inserted;
    try {
      inserted = await _client
          .from('scan_history')
          .insert({
            'user_id': ownerId,
            'estimated_calories': result.totalEstimatedCalories,
            'scan_result': result.toJson(),
            'scanned_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw DataFailure(_message(error));
    }

    if (imageBytes == null) return ScanHistoryEntry.fromJson(inserted);
    final id = inserted['id']! as String;
    final extension = mimeType == 'image/png' ? 'png' : 'jpg';
    final path = '$ownerId/$id/image.$extension';
    try {
      await _client.storage
          .from('food-scans')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? 'image/jpeg',
              upsert: false,
            ),
          );
      final updated = await _client
          .from('scan_history')
          .update({'image_path': path})
          .eq('id', id)
          .select()
          .single();
      return ScanHistoryEntry.fromJson(updated);
    } on StorageException catch (_) {
      await _client.from('scan_history').delete().eq('id', id);
      throw const DataFailure(
        'Foto belum dapat disimpan. Pilih opsi jangan simpan foto lalu coba lagi.',
      );
    } on PostgrestException catch (error) {
      await _client.storage.from('food-scans').remove([path]);
      await _client.from('scan_history').delete().eq('id', id);
      throw DataFailure(_message(error));
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }

  String _message(PostgrestException error) => error.code == '42501'
      ? 'Kamu tidak memiliki izin untuk riwayat scan ini.'
      : 'Riwayat scan belum dapat diproses. Coba lagi.';
}

class UnavailableScanRepository implements ScanRepository {
  const UnavailableScanRepository();

  Future<T> _unavailable<T>() => Future<T>.error(const ConfigurationFailure());

  @override
  Future<List<ScanHistoryEntry>> listHistory() => _unavailable();

  @override
  Future<ScanHistoryEntry> saveHistory(
    FoodScanResult result, {
    Uint8List? imageBytes,
    String? mimeType,
  }) => _unavailable();
}
