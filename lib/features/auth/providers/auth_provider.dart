import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

final passwordRecoveryProvider = StateProvider<bool>((ref) => false);
final authInitializingProvider = StateProvider<bool>((ref) => true);

class AuthNotifier extends Notifier<UserModel?> {
  SupabaseClient get _client => Supabase.instance.client;

  void setDemoUser() {
    state = const UserModel(
      id: 'demo_user_123',
      email: 'alex@example.com',
      displayName: 'Alex',
      isProfileComplete: true,
    );
  }

  @override
  UserModel? build() {
    // Listen to real Supabase auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(passwordRecoveryProvider.notifier).state = true;
      }
      final session = data.session;
      if (session == null) {
        state = null;
        ref.read(authInitializingProvider.notifier).state = false;
      } else {
        _loadUserProfile(session.user);
      }
    });

    if (kIsWeb) {
      final href = Uri.base.toString();
      if (href.contains('type=recovery') || href.contains('reset-password')) {
        Future.microtask(() {
          ref.read(passwordRecoveryProvider.notifier).state = true;
        });
      }
    }

    if (kIsWeb && Uri.base.toString().contains('demo=true')) {
      Future.microtask(() {
        ref.read(authInitializingProvider.notifier).state = false;
      });
      return const UserModel(
        id: 'demo_user_123',
        email: 'athlete@fitstack.com',
        displayName: 'FitStack Athlete',
        isProfileComplete: true,
      );
    }

    // Check existing session on initial load
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      final supaUser = currentSession.user;
      final provisionalUser = UserModel(
        id: supaUser.id,
        email: supaUser.email ?? '',
        displayName: supaUser.userMetadata?['full_name'] as String? ??
            supaUser.email?.split('@').first ??
            'FitStack Athlete',
        isProfileComplete: true,
      );

      Future.microtask(() {
        _loadUserProfile(supaUser);
        ref.read(authInitializingProvider.notifier).state = false;
      });

      return provisionalUser;
    } else {
      Future.microtask(() {
        ref.read(authInitializingProvider.notifier).state = false;
      });
    }

    return null;
  }

  Future<void> _loadUserProfile(User supaUser) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', supaUser.id)
          .maybeSingle();

      if (response != null) {
        state = UserModel.fromMap(response);
      } else {
        // Create initial profile row if not yet exists
        final initialModel = UserModel(
          id: supaUser.id,
          email: supaUser.email ?? '',
          displayName: supaUser.userMetadata?['full_name'] as String? ??
              supaUser.email?.split('@').first ??
              'FitStack Athlete',
          isProfileComplete: false,
        );
        state = initialModel;
        await _client.from('profiles').upsert(initialModel.toMap());
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Error loading profile: $e');
      state = UserModel(
        id: supaUser.id,
        email: supaUser.email ?? '',
        displayName: supaUser.email?.split('@').first ?? 'FitStack Athlete',
        isProfileComplete: false,
      );
    }
  }

  /// Real Supabase Sign-in with Email and Password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.user != null) {
      await _loadUserProfile(response.user!);
    }
  }

  /// Real Supabase Sign-up with Email and Password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (response.user != null) {
      final newUser = response.user!;
      final newProfile = UserModel(
        id: newUser.id,
        email: newUser.email ?? email.trim(),
        displayName: email.trim().split('@').first,
        isProfileComplete: false,
      );

      // Create profile row in profiles table with RLS compliance
      try {
        await _client.from('profiles').upsert(newProfile.toMap());
      } catch (e) {
        debugPrint('[AuthNotifier] Error creating initial profile row: $e');
      }

      state = newProfile;
    }
  }

  /// Real Supabase OAuth with Google
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'fitstack://login-callback',
    );
  }

  /// Update profile and mark onboarding as complete
  Future<void> completeOnboarding({
    required double weight,
    required double height,
    required int age,
    required String biologicalSex,
    required String goal,
    required String level,
    List<String> healthConcerns = const [],
    String? otherHealthConcern,
    String bodyType = 'Average',
  }) async {
    if (state != null) {
      final updated = state!.copyWith(
        isProfileComplete: true,
        weightKg: weight,
        heightCm: height,
        age: age,
        biologicalSex: biologicalSex,
        primaryGoal: goal,
        experienceLevel: level,
        healthConcerns: healthConcerns,
        otherHealthConcern: otherHealthConcern,
        bodyType: bodyType,
      );
      state = updated;

      try {
        await _client.from('profiles').upsert(updated.toMap());
      } catch (e) {
        debugPrint('[AuthNotifier] Error updating onboarding profile: $e');
      }
    }
  }

  /// Update user profile attributes and save to Supabase
  Future<void> updateProfile(UserModel updatedUser) async {
    state = updatedUser;
    try {
      await _client.from('profiles').upsert(updatedUser.toMap());
      debugPrint('[AuthNotifier] Profile successfully saved to Supabase profiles table.');
    } catch (e) {
      debugPrint('[AuthNotifier] Error saving profile to Supabase: $e');
    }
  }

  /// Send password reset email via Supabase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    final origin = kIsWeb ? Uri.base.origin : 'https://fit-stack-flax.vercel.app';
    final cleanOrigin = origin.split('#').first.replaceAll(RegExp(r'/$'), '');
    final redirectUrl = '$cleanOrigin/#/reset-password';

    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  /// Update user password in Supabase Auth
  Future<void> updatePassword(String newPassword) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (response.user != null) {
      await _loadUserProfile(response.user!);
    }
  }

  /// Real Supabase Sign-out
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthNotifier] Error on sign-out: $e');
    }
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});
