import 'package:caloris/app/caloris_app.dart';
import 'package:caloris/core/config/app_environment.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const environment = AppEnvironment.fromDefines();
  if (environment.isConfigured) {
    await Supabase.initialize(
      url: environment.supabaseUrl,
      publishableKey: environment.supabasePublishableKey,
    );
  }

  runApp(CalorisApp(environment: environment));
}
