import 'app_user.dart';
import 'user_role.dart';

abstract class AuthRepository {
  Future<AppUser?> currentUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required UserRole role,
    String? schoolId,
  });

  Future<void> signOut();
}
