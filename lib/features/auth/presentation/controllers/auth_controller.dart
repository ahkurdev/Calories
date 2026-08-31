import 'dart:async';

import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/auth/data/supabase_auth_repository.dart';
import 'package:caloris/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthViewState>(
  AuthController.new,
);

class AuthViewState {
  const AuthViewState({
    required this.session,
    this.isLoading = false,
    this.message,
  });

  final AuthSessionState session;
  final bool isLoading;
  final String? message;

  AuthViewState copyWith({
    AuthSessionState? session,
    bool? isLoading,
    String? message,
    bool clearMessage = false,
  }) => AuthViewState(
    session: session ?? this.session,
    isLoading: isLoading ?? this.isLoading,
    message: clearMessage ? null : message ?? this.message,
  );
}

class AuthController extends Notifier<AuthViewState> {
  @override
  AuthViewState build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.sessionChanges.listen((session) {
      state = state.copyWith(
        session: session,
        isLoading: false,
        clearMessage: true,
      );
    });
    ref.onDispose(subscription.cancel);
    return AuthViewState(session: repository.currentSession);
  }

  Future<bool> signIn({required String email, required String password}) =>
      _perform(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  Future<bool> register({required String email, required String password}) =>
      _perform(
        () => ref
            .read(authRepositoryProvider)
            .register(email: email, password: password),
      );

  Future<bool> requestPasswordReset(String email) => _perform(
    () => ref.read(authRepositoryProvider).requestPasswordReset(email),
  );

  Future<bool> updatePassword(String password) =>
      _perform(() => ref.read(authRepositoryProvider).updatePassword(password));

  Future<bool> signOut() => _perform(ref.read(authRepositoryProvider).signOut);

  void clearMessage() => state = state.copyWith(clearMessage: true);

  Future<bool> _perform(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(isLoading: false, message: failure.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isLoading: false,
        message: 'Terjadi kendala. Silakan coba lagi.',
      );
      return false;
    }
  }
}
