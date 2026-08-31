import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/core/routing/app_router.dart';
import 'package:caloris/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalorisApp extends StatelessWidget {
  const CalorisApp({required this.environment, super.key});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [appEnvironmentProvider.overrideWithValue(environment)],
    child: const _CalorisAppView(),
  );
}

class _CalorisAppView extends ConsumerWidget {
  const _CalorisAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Caloris',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: ref.watch(appRouterProvider),
  );
}
