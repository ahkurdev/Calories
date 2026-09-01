import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/errors/app_failure.dart';
import 'package:caloris/features/auth/data/auth_error_messages.dart';
import 'package:caloris/features/auth/domain/auth_redirects.dart';
import 'package:caloris/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (!environment.isConfigured) return const UnavailableAuthRepository();
  return SupabaseAuthRepository(Supabase.instance.client);
});

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthSessionState get currentSession {
    final user = _client.auth.currentUser;
    return user == null
        ? const AuthSessionState.unauthenticated()
        : AuthSessionState(status: AuthStatus.authenticated, userId: user.id);
  }

  @override
  Stream<AuthSessionState> get sessionChanges =>
      _client.auth.onAuthStateChange.map((data) {
        final userId = data.session?.user.id ?? _client.auth.currentUser?.id;
        if (data.event == AuthChangeEvent.passwordRecovery) {
          return AuthSessionState(
            status: AuthStatus.passwordRecovery,
            userId: userId,
          );
        }
        return userId == null
            ? const AuthSessionState.unauthenticated()
            : AuthSessionState(
                status: AuthStatus.authenticated,
                userId: userId,
              );
      });

  @override
  Future<void> register({required String email, required String password}) =>
      _guard(() async {
        await _client.auth.signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: AuthRedirects.emailConfirmation,
        );
      });

  @override
  Future<void> requestPasswordReset(String email) => _guard(() async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AuthRedirects.passwordRecovery,
    );
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> signOut() => _guard(_client.auth.signOut);

  @override
  Future<void> updatePassword(String password) => _guard(() async {
    await _client.auth.updateUser(UserAttributes(password: password));
  });

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
    } on AuthException catch (error) {
      throw AuthenticationFailure(friendlyAuthMessage(error));
    } on Exception {
      throw const AuthenticationFailure(
        'Tidak dapat terhubung ke layanan akun. Coba lagi.',
      );
    }
  }
}

class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  @override
  AuthSessionState get currentSession =>
      const AuthSessionState.unauthenticated();

  @override
  Stream<AuthSessionState> get sessionChanges => const Stream.empty();

  @override
  Future<void> register({required String email, required String password}) =>
      Future<void>.error(const ConfigurationFailure());

  @override
  Future<void> requestPasswordReset(String email) =>
      Future<void>.error(const ConfigurationFailure());

  @override
  Future<void> signIn({required String email, required String password}) =>
      Future<void>.error(const ConfigurationFailure());

  @override
  Future<void> signOut() => Future<void>.error(const ConfigurationFailure());

  @override
  Future<void> updatePassword(String password) =>
      Future<void>.error(const ConfigurationFailure());
}
