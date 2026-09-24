import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_state.dart';

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  void updateWeight(double? weight) {
    final newErrors = Map<String, String>.from(state.errors)..remove('weight');
    state = state.copyWith(weightKg: weight, errors: newErrors);
  }

  void updateHeight(double? height) {
    final newErrors = Map<String, String>.from(state.errors)..remove('height');
    state = state.copyWith(heightCm: height, errors: newErrors);
  }

  void updateAge(int? age) {
    final newErrors = Map<String, String>.from(state.errors)..remove('age');
    state = state.copyWith(age: age, errors: newErrors);
  }

  void updateBiologicalSex(String sex) {
    state = state.copyWith(biologicalSex: sex);
  }

  void updateExperienceLevel(String level) {
    final newErrors = Map<String, String>.from(state.errors)..remove('level');
    state = state.copyWith(experienceLevel: level, errors: newErrors);
  }

  void updatePrimaryGoal(String goal) {
    final newErrors = Map<String, String>.from(state.errors)..remove('goal');
    state = state.copyWith(primaryGoal: goal, errors: newErrors);
  }

  void toggleHealthConcern(String concern) {
    final current = List<String>.from(state.healthConcerns);
    if (concern == 'None') {
      state = state.copyWith(healthConcerns: ['None']);
      return;
    }
    current.remove('None');
    if (current.contains(concern)) {
      current.remove(concern);
      if (current.isEmpty) {
        current.add('None');
      }
    } else {
      current.add(concern);
    }
    state = state.copyWith(healthConcerns: current);
  }

  void updateOtherHealthConcern(String text) {
    state = state.copyWith(otherHealthConcern: text);
  }

  void updateBodyType(String bodyType) {
    state = state.copyWith(bodyType: bodyType);
  }

  bool validateProfileStep() {
    final Map<String, String> errors = {};

    if (state.weightKg == null || state.weightKg! <= 0) {
      errors['weight'] = 'Please enter a valid weight (> 0 kg)';
    }

    if (state.heightCm == null || state.heightCm! <= 0) {
      errors['height'] = 'Please enter a valid height (> 0 cm)';
    }

    if (state.age == null || state.age! <= 0) {
      errors['age'] = 'Please enter a valid age (> 0)';
    }

    if (state.experienceLevel == null || state.experienceLevel!.isEmpty) {
      errors['level'] = 'Please select your experience level';
    }

    if (state.primaryGoal == null || state.primaryGoal!.isEmpty) {
      errors['goal'] = 'Please select your primary goal';
    }

    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }

    state = state.copyWith(currentStep: 1, errors: {});
    return true;
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});
