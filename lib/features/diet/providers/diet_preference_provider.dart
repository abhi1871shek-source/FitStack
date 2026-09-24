import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/diet_preference_state.dart';

class DietPreferenceNotifier extends Notifier<DietPreferenceState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  DietPreferenceState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchPreferences();
      } else {
        state = const DietPreferenceState();
      }
    });

    Future.microtask(() => fetchPreferences());

    return const DietPreferenceState();
  }

  /// Load user's diet preferences from Supabase (or create initial row if missing)
  Future<void> fetchPreferences() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final response = await _client
          .from('diet_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        state = DietPreferenceState.fromMap(response);
      } else {
        final onboarding = ref.read(onboardingProvider);
        final calculatedCalories = _calculateTdee(
          weightKg: onboarding.weightKg ?? 70.0,
          heightCm: onboarding.heightCm ?? 175.0,
          age: onboarding.age ?? 25,
          sex: onboarding.biologicalSex,
          level: onboarding.experienceLevel ?? 'Beginner',
          goal: onboarding.primaryGoal ?? 'Maintain',
        );

        final initialState = DietPreferenceState(calorieTarget: calculatedCalories);
        state = initialState;

        await _client
            .from('diet_preferences')
            .upsert(initialState.toMap(userId: userId), onConflict: 'user_id');
      }
    } catch (e, st) {
      debugPrint('[DietPreferenceNotifier] Error fetching preferences: $e\n$st');
    }
  }

  /// Mifflin-St Jeor BMR → multiply by activity factor → apply goal adjustment
  static int _calculateTdee({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex,
    required String level,
    required String goal,
  }) {
    final double bmr = sex.toLowerCase() == 'female'
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;

    final double activityFactor = switch (level.toLowerCase()) {
      'intermediate' => 1.55,
      'expert' => 1.725,
      _ => 1.375,
    };

    final double tdee = bmr * activityFactor;

    final double adjusted = switch (goal.toLowerCase()) {
      'weight loss' => tdee - 500,
      'weight gain' || 'build muscle' => tdee + 400,
      _ => tdee,
    };

    return adjusted.round().clamp(1200, 5000);
  }

  Future<void> _persistState(DietPreferenceState newState) async {
    state = newState;
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      await _client
          .from('diet_preferences')
          .upsert(newState.toMap(userId: userId), onConflict: 'user_id');
    } catch (e) {
      debugPrint('[DietPreferenceNotifier] Error persisting preference: $e');
    }
  }

  void toggleCuisine(String cuisine) {
    final current = List<String>.from(state.selectedCuisines);
    if (current.contains(cuisine)) {
      if (current.length > 1) current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    _persistState(state.copyWith(selectedCuisines: current));
  }

  void setDietaryType(String type) {
    _persistState(state.copyWith(dietaryType: type));
  }

  void setMealsPerDay(int meals) {
    _persistState(state.copyWith(mealsPerDay: meals));
  }

  void setCalorieTarget(int calories) {
    _persistState(state.copyWith(
      calorieTarget: calories.clamp(1200, 5000),
      isCalorieManuallyOverridden: true,
    ));
  }

  void resetCalorieToCalculated() {
    final onboarding = ref.read(onboardingProvider);
    final calc = _calculateTdee(
      weightKg: onboarding.weightKg ?? 70.0,
      heightCm: onboarding.heightCm ?? 175.0,
      age: onboarding.age ?? 25,
      sex: onboarding.biologicalSex,
      level: onboarding.experienceLevel ?? 'Beginner',
      goal: onboarding.primaryGoal ?? 'Maintain',
    );
    _persistState(state.copyWith(
      calorieTarget: calc,
      isCalorieManuallyOverridden: false,
    ));
  }

  int get calculatedCalories {
    final onboarding = ref.read(onboardingProvider);
    return _calculateTdee(
      weightKg: onboarding.weightKg ?? 70.0,
      heightCm: onboarding.heightCm ?? 175.0,
      age: onboarding.age ?? 25,
      sex: onboarding.biologicalSex,
      level: onboarding.experienceLevel ?? 'Beginner',
      goal: onboarding.primaryGoal ?? 'Maintain',
    );
  }
}

final dietPreferenceProvider =
    NotifierProvider<DietPreferenceNotifier, DietPreferenceState>(
  () => DietPreferenceNotifier(),
);
