import 'dart:io';

import 'package:caloris/core/offline/offline_first_profile_repository.dart';
import 'package:caloris/core/offline/offline_store.dart';
import 'package:caloris/features/profile/domain/profile_repository.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cached profile is available offline and isolated by owner', () async {
    final remote = _FakeProfileRepository();
    final store = _ProfileMemoryStore();
    final userOne = OfflineFirstProfileRepository(
      remote,
      store,
      () => 'user-1',
    );

    final online = await userOne.fetchCurrent();
    remote.online = false;
    final offline = await userOne.fetchCurrent();

    expect(offline?.name, online?.name);

    final userTwo = OfflineFirstProfileRepository(
      remote,
      store,
      () => 'user-2',
    );
    await expectLater(userTwo.fetchCurrent(), throwsA(isA<SocketException>()));
  });
}

class _FakeProfileRepository implements ProfileRepository {
  bool online = true;

  @override
  Future<UserProfile?> fetchCurrent() async {
    if (!online) throw const SocketException('offline');
    return UserProfile(
      id: 'user-1',
      name: 'Allan',
      gender: Gender.preferNotToSay,
      birthDate: DateTime(1995, 1, 1),
      heightCm: 170,
      currentWeightKg: 70,
      targetWeightKg: 65,
      activityLevel: ActivityLevel.lightlyActive,
      goal: HealthGoal.loseWeight,
    );
  }

  @override
  Future<UserProfile> save(UserProfile profile) async => profile;
}

class _ProfileMemoryStore implements OfflineStore {
  final cache = <String, String>{};

  @override
  Future<void> writeCache({
    required String ownerId,
    required String cacheKey,
    required String payload,
  }) async => cache['$ownerId:$cacheKey'] = payload;

  @override
  Future<String?> readCache({
    required String ownerId,
    required String cacheKey,
  }) async => cache['$ownerId:$cacheKey'];

  @override
  Future<void> clearOwner(String ownerId) async =>
      cache.removeWhere((key, _) => key.startsWith('$ownerId:'));

  @override
  Future<void> enqueue(OutboxMutation mutation) async {}

  @override
  Future<void> incrementAttempt(String id) async {}

  @override
  Future<List<OutboxMutation>> pending({
    required String ownerId,
    required String entity,
    int limit = 20,
  }) async => const [];

  @override
  Future<void> removeMutation(String id) async {}

  @override
  Future<void> removeRecordFromCaches({
    required String ownerId,
    required String cachePrefix,
    required String recordId,
  }) async {}
}
