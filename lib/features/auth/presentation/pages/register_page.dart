import 'package:caloris/core/utils/input_validators.dart';
import 'package:caloris/features/auth/domain/auth_messages.dart';
import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/auth/presentation/widgets/auth_shell.dart';
import 'package:caloris/shared/widgets/async_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.message != null && next.message != previous?.message) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.message!)));
      }
    });
    final state = ref.watch(authControllerProvider);
    return AuthShell(
      title: 'Buat akun Caloris',
      subtitle: 'Profil kesehatanmu akan diisi setelah akun terverifikasi.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.newUsername],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: InputValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                helperText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: InputValidators.password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscurePassword,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Ulangi kata sandi',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Kata sandi belum sama.'
                  : null,
            ),
            const SizedBox(height: 24),
            AsyncActionButton(
              label: 'Daftar',
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.isLoading ? null : () => context.go('/login'),
              child: const Text('Sudah punya akun? Masuk'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (success && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined),
          title: const Text('Konfirmasi email Anda'),
          content: const Text(signupConfirmationMessage),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
              child: const Text('Ke halaman masuk'),
            ),
          ],
        ),
      );
    }
  }
}
