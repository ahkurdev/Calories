import 'package:caloris/features/profile/domain/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrent();
  Future<UserProfile> save(UserProfile profile);
}
