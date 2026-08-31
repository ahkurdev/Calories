import 'dart:async';

import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/auth/data/supabase_auth_repository.dart';
import 'package:caloris/features/auth/domain/auth_repository.dart';
import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthController delegates sign in through its repository', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'person@example.com', password: 'password123');

    expect(success, isTrue);
    expect(repository.lastEmail, 'person@example.com');
    expect(container.read(authControllerProvider).isLoading, isFalse);
  });

  test('AuthController exposes a friendly application failure', () async {
    final repository = _FakeAuthRepository(
      signInFailure: const AuthenticationFailure('Email belum tepat.'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.dispose();
    });

    final success = await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'person@example.com', password: 'password123');

    expect(success, isFalse);
    expect(
      container.read(authControllerProvider).message,
      'Email belum tepat.',
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.signInFailure});

  final AuthenticationFailure? signInFailure;
  final _changes = StreamController<AuthSessionState>.broadcast();
  String? lastEmail;

  Future<void> dispose() => _changes.close();

  @override
  AuthSessionState get currentSession =>
      const AuthSessionState.unauthenticated();

  @override
  Stream<AuthSessionState> get sessionChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastEmail = email;
    if (signInFailure != null) throw signInFailure!;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) async {}
}
