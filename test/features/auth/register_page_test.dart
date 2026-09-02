import 'dart:async';

import 'package:caloris/features/auth/data/supabase_auth_repository.dart';
import 'package:caloris/features/auth/domain/auth_messages.dart';
import 'package:caloris/features/auth/domain/auth_repository.dart';
import 'package:caloris/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('successful registration asks the user to confirm email', (
    tester,
  ) async {
    final repository = _RegisterAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: RegisterPage()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata sandi'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ulangi kata sandi'),
      'password123',
    );
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text(signupConfirmationMessage), findsOneWidget);
    expect(find.text('Ke halaman masuk'), findsOneWidget);
  });
}

class _RegisterAuthRepository implements AuthRepository {
  final _changes = StreamController<AuthSessionState>.broadcast();

  Future<void> dispose() => _changes.close();

  @override
  AuthSessionState get currentSession =>
      const AuthSessionState.unauthenticated();

  @override
  Stream<AuthSessionState> get sessionChanges => _changes.stream;

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) async {}
}
