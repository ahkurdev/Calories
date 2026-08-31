import 'package:flutter_riverpod/flutter_riverpod.dart';

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => throw StateError('AppEnvironment has not been provided.'),
);

class AppEnvironment {
  const AppEnvironment({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.useMockAi = false,
  });

  const AppEnvironment.fromDefines()
    : supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
      ),
      useMockAi = const bool.fromEnvironment('CALORIS_USE_MOCK_AI');

  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool useMockAi;

  bool get isConfigured =>
      Uri.tryParse(supabaseUrl)?.hasScheme == true &&
      supabasePublishableKey.trim().isNotEmpty;
}
