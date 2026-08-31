enum AuthStatus { unauthenticated, authenticated, passwordRecovery }

class AuthSessionState {
  const AuthSessionState({required this.status, this.userId});

  const AuthSessionState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      userId = null;

  final AuthStatus status;
  final String? userId;
}

abstract interface class AuthRepository {
  AuthSessionState get currentSession;
  Stream<AuthSessionState> get sessionChanges;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> requestPasswordReset(String email);

  Future<void> updatePassword(String password);

  Future<void> signOut();
}
