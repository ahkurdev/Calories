import 'package:caloris/features/auth/presentation/controllers/auth_controller.dart';
import 'package:caloris/features/profile/data/supabase_profile_repository.dart';
import 'package:caloris/features/profile/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final auth = ref.watch(authControllerProvider);
    if (auth.session.userId == null) return null;
    return ref.read(profileRepositoryProvider).fetchCurrent();
  }

  Future<bool> save(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).save(profile),
    );
    return !state.hasError;
  }

  Future<void> reload() async => ref.invalidateSelf();
}
