import 'package:caloris/features/auth/domain/auth_redirects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android Auth redirects use separate confirmation and recovery hosts',
    () {
      expect(AuthRedirects.emailConfirmation, 'caloris://auth-callback');
      expect(AuthRedirects.passwordRecovery, 'caloris://reset-password');
      expect(
        Uri.parse(AuthRedirects.emailConfirmation).host,
        isNot(Uri.parse(AuthRedirects.passwordRecovery).host),
      );
    },
  );
}
