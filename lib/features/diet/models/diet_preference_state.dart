/// Diet Preference state — holds cuisine selections, dietary type,
/// manually-overridden calorie target, and meals-per-day setting.
class DietPreferenceState {
  final List<String> selectedCuisines; // subset of all 6 cuisines
  final String dietaryType; // 'vegetarian' | 'vegan' | 'eggetarian' | 'non-vegetarian'
  final int mealsPerDay; // 3 | 4 | 5
  final int? calorieTarget;
  final bool isCalorieManuallyOverridden;

  const DietPreferenceState({
    this.selectedCuisines = const ['Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese'],
    this.dietaryType = 'non-vegetarian',
    this.mealsPerDay = 4,
    this.calorieTarget,
    this.isCalorieManuallyOverridden = false,
  });

  DietPreferenceState copyWith({
    List<String>? selectedCuisines,
    String? dietaryType,
    int? mealsPerDay,
    int? calorieTarget,
    bool? isCalorieManuallyOverridden,
  }) {
    return DietPreferenceState(
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      dietaryType: dietaryType ?? this.dietaryType,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      isCalorieManuallyOverridden: isCalorieManuallyOverridden ?? this.isCalorieManuallyOverridden,
    );
  }

  factory DietPreferenceState.fromMap(Map<String, dynamic> map) {
    return DietPreferenceState(
      selectedCuisines: (map['selected_cuisines'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese'],
      dietaryType: map['dietary_type'] as String? ?? 'non-vegetarian',
      mealsPerDay: map['meals_per_day'] as int? ?? 4,
      calorieTarget: map['calorie_target'] as int?,
      isCalorieManuallyOverridden: map['is_calorie_manually_overridden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    return {
      'user_id': userId,
      'selected_cuisines': selectedCuisines,
      'dietary_type': dietaryType,
      'meals_per_day': mealsPerDay,
      'calorie_target': calorieTarget ?? 2000,
      'is_calorie_manually_overridden': isCalorieManuallyOverridden,
    };
  }
}
