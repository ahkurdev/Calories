import 'package:caloris/features/auth/data/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('friendlyAuthMessage', () {
    test('maps the current invalid credentials response', () {
      const error = AuthException(
        'Invalid credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );

      expect(friendlyAuthMessage(error), 'Email atau kata sandi belum tepat.');
    });

    test('explains that email confirmation is still required', () {
      const error = AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      );

      expect(
        friendlyAuthMessage(error),
        'Email belum dikonfirmasi. Buka tautan konfirmasi di email, lalu coba masuk lagi.',
      );
    });
  });
}
