import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/profile/presentation/controllers/profile_controller.dart';
import 'package:caloris/features/profile/presentation/widgets/profile_form.dart';
import 'package:caloris/shared/widgets/brand_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(compact: true),
                  const SizedBox(height: 32),
                  Text(
                    'Kenali kebutuhanmu',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data ini digunakan untuk menghitung kebutuhan kalori di '
                    'fase berikutnya dan dapat diubah kapan saja.',
                  ),
                  const SizedBox(height: 24),
                  ProfileForm(
                    userId: auth.session.userId ?? '',
                    isLoading: profile.isLoading,
                    submitLabel: 'Selesaikan profil',
                    onSubmit: (value) async {
                      final success = await ref
                          .read(profileControllerProvider.notifier)
                          .save(value);
                      if (!success && context.mounted) {
                        final error = ref.read(profileControllerProvider).error;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error?.toString() ??
                                  'Profil belum dapat disimpan.',
                            ),
                          ),
                        );
                      }
                    },
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
