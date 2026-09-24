class OnboardingState {
  final int currentStep; // 0 = Profile, 1 = Review
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String biologicalSex; // 'Male' | 'Female'
  final String? experienceLevel; // 'Beginner' | 'Intermediate' | 'Expert'
  final String? primaryGoal; // 'Weight Loss' | 'Weight Gain' | 'Maintain' | 'Build Muscle'
  final List<String> healthConcerns; // e.g. ['Back Pain', 'Knee Pain', 'Joint Issues', 'None']
  final String otherHealthConcern;
  final String bodyType; // 'Lean' | 'Average' | 'Chubby' | 'Heavy'
  final Map<String, String> errors;

  const OnboardingState({
    this.currentStep = 0,
    this.weightKg = 70.0,
    this.heightCm = 175.0,
    this.age = 25,
    this.biologicalSex = 'Male',
    this.experienceLevel = 'Beginner',
    this.primaryGoal = 'Weight Loss',
    this.healthConcerns = const ['None'],
    this.otherHealthConcern = '',
    this.bodyType = 'Average',
    this.errors = const {},
  });

  OnboardingState copyWith({
    int? currentStep,
    double? weightKg,
    double? heightCm,
    int? age,
    String? biologicalSex,
    String? experienceLevel,
    String? primaryGoal,
    List<String>? healthConcerns,
    String? otherHealthConcern,
    String? bodyType,
    Map<String, String>? errors,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      otherHealthConcern: otherHealthConcern ?? this.otherHealthConcern,
      bodyType: bodyType ?? this.bodyType,
      errors: errors ?? this.errors,
    );
  }
}
