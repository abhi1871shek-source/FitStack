import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthNotifier extends Notifier<UserModel?> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  UserModel? build() {
    // Listen to real Supabase auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        state = null;
      } else {
        _loadUserProfile(session.user);
      }
    });

    // Check existing session on initial load
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      // Async profile load
      Future.microtask(() => _loadUserProfile(currentSession.user));
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
