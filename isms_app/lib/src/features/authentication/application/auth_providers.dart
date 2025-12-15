import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../../../core/network/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.currentUser();
});

// Auth state notifier that tracks login status
class AuthStateNotifier extends StateNotifier<AppUser?> {
  AuthStateNotifier(this._repo) : super(null) {
    _init();
  }

  final AuthRepository _repo;

  void _init() {
    SupabaseManager.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _loadUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _repo.currentUser();
    state = user;
  }

  Future<void> signIn(String email, String password) async {
    final user = await _repo.signInWithEmail(email: email, password: password);
    state = user;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((
  ref,
) {
  final repo = ref.read(authRepositoryProvider);
  return AuthStateNotifier(repo);
});
