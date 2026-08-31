import 'package:caloris/core/config/app_environment.dart';
import 'package:caloris/features/auth/domain/auth_repository.dart';
import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/auth/presentation/pages/login_page.dart';
import 'package:caloris/features/auth/presentation/pages/password_pages.dart';
import 'package:caloris/features/auth/presentation/pages/register_page.dart';
import 'package:caloris/features/dashboard/presentation/pages/home_page.dart';
import 'package:caloris/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final auth = ref.watch(authControllerProvider);
  final profile = ref.watch(profileControllerProvider);

  return GoRouter(
    initialLocation: environment.isConfigured ? '/login' : '/setup',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!environment.isConfigured) {
        return location == '/setup' ? null : '/setup';
      }

      final isAuthRoute = <String>{
        '/login',
        '/register',
        '/forgot-password',
      }.contains(location);

      if (auth.session.status == AuthStatus.passwordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }
      if (auth.session.userId == null) {
        return isAuthRoute ? null : '/login';
      }
      if (profile.isLoading || profile.hasError) {
        return location == '/loading' ? null : '/loading';
      }
      if (profile.value == null) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      if (isAuthRoute ||
          location == '/onboarding' ||
          location == '/loading' ||
          location == '/reset-password') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, _) => const SetupRequiredPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(path: '/loading', builder: (_, _) => const ProfileLoadingPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
    ],
  );
});

class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_suggest_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      'Supabase belum dikonfigurasi',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Salin .env.example menjadi .env, isi public project URL '
                      'dan publishable key, lalu jalankan dengan '
                      '--dart-define-from-file=.env. Tidak ada AI yang '
                      'disimulasikan pada mode ini.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfileLoadingPage extends ConsumerWidget {
  const ProfileLoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    if (profile.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52),
                const SizedBox(height: 16),
                Text(profile.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(profileControllerProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
