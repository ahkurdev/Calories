import 'package:caloris/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment', () {
    test('is configured only with a URL and publishable key', () {
      const configured = AppEnvironment(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test',
      );
      const missingKey = AppEnvironment(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: '',
      );

      expect(configured.isConfigured, isTrue);
      expect(missingKey.isConfigured, isFalse);
    });
  });
}
