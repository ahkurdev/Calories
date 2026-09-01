import 'dart:convert';

import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/core/offline/offline_store.dart';
import 'package:caloris/features/profile/domain/profile_repository.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';

class OfflineFirstProfileRepository implements ProfileRepository {
  const OfflineFirstProfileRepository(
    this._remote,
    this._store,
    this._currentUserId,
  );

  static const _cacheKey = 'profile';

  final ProfileRepository _remote;
  final OfflineStore _store;
  final String? Function() _currentUserId;

  @override
  Future<UserProfile?> fetchCurrent() async {
    final ownerId = _requireUserId();
    try {
      final profile = await _remote.fetchCurrent();
      if (profile != null) await _write(ownerId, profile);
      return profile;
    } on Object catch (error, stackTrace) {
      final cached = await _read(ownerId);
      if (cached != null) return cached;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    final ownerId = _requireUserId();
    final saved = await _remote.save(profile.copyWith(id: ownerId));
    await _write(ownerId, saved);
    return saved;
  }

  Future<void> _write(String ownerId, UserProfile profile) => _store.writeCache(
    ownerId: ownerId,
    cacheKey: _cacheKey,
    payload: jsonEncode(profile.toJson()),
  );

  Future<UserProfile?> _read(String ownerId) async {
    final payload = await _store.readCache(
      ownerId: ownerId,
      cacheKey: _cacheKey,
    );
    if (payload == null) return null;
    try {
      return UserProfile.fromJson(
        Map<String, Object?>.from(jsonDecode(payload) as Map),
      );
    } on Object {
      return null;
    }
  }

  String _requireUserId() {
    final id = _currentUserId();
    if (id == null) {
      throw const AuthenticationFailure(
        'Sesi telah berakhir. Silakan masuk lagi.',
      );
    }
    return id;
  }
}
