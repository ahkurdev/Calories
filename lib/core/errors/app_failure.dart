sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(super.message);
}

final class DataFailure extends AppFailure {
  const DataFailure(super.message);
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure()
    : super('Konfigurasi Supabase belum tersedia untuk build ini.');
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}
