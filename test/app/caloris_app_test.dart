import 'package:caloris/app/caloris_app.dart';
import 'package:caloris/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an honest setup state when Supabase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CalorisApp(
        environment: AppEnvironment(
          supabaseUrl: '',
          supabasePublishableKey: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supabase belum dikonfigurasi'), findsOneWidget);
    expect(
      find.textContaining('Tidak ada AI yang disimulasikan'),
      findsOneWidget,
    );
  });
}
