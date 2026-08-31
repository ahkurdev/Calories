import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/profile/presentation/widgets/profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(profileControllerProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (value) => value == null
            ? const Center(child: Text('Profil belum tersedia.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileForm(
                          userId: auth.session.userId ?? '',
                          initialProfile: value,
                          isLoading: profile.isLoading,
                          onSubmit: (updated) async {
                            final success = await ref
                                .read(profileControllerProvider.notifier)
                                .save(updated);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil berhasil diperbarui.'),
                                ),
                              );
                              context.go('/home');
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Keluar dari akun'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
