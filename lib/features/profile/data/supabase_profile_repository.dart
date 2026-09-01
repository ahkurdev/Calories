import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/core/offline/offline_first_profile_repository.dart';
import 'package:caloris/core/offline/sqlite_offline_store.dart';
import 'package:caloris/features/profile/domain/profile_repository.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableProfileRepository();
  final client = Supabase.instance.client;
  return OfflineFirstProfileRepository(
    SupabaseProfileRepository(client),
    ref.watch(offlineStoreProvider),
    () => client.auth.currentUser?.id,
  );
});

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> fetchCurrent() async {
    final userId = _requireUserId();
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data == null ? null : UserProfile.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_friendlyDataMessage(error));
    } on AppFailure {
      rethrow;
    } on Exception {
      throw const DataFailure('Profil belum dapat dimuat. Coba lagi.');
    }
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    final ownedProfile = profile.copyWith(id: _requireUserId());
    ownedProfile.validate();
    try {
      final data = await _client
          .from('profiles')
          .upsert(ownedProfile.toJson(), onConflict: 'id')
          .select()
          .single();
      return UserProfile.fromJson(data);
    } on PostgrestException catch (error) {
      throw DataFailure(_friendlyDataMessage(error));
    } on AppFailure {
      rethrow;
    } on Exception {
      throw const DataFailure('Profil belum dapat disimpan. Coba lagi.');
    }
  }

  String _friendlyDataMessage(PostgrestException error) {
    if (error.code == '42501') {
      return 'Kamu tidak memiliki izin untuk data profil ini.';
    }
    if (error.code == '23514') return 'Ada nilai profil yang belum valid.';
    return 'Layanan profil sedang mengalami kendala. Coba lagi.';
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
}

class UnavailableProfileRepository implements ProfileRepository {
  const UnavailableProfileRepository();

  @override
  Future<UserProfile?> fetchCurrent() =>
      Future<UserProfile?>.error(const ConfigurationFailure());

  @override
  Future<UserProfile> save(UserProfile profile) =>
      Future<UserProfile>.error(const ConfigurationFailure());
}
