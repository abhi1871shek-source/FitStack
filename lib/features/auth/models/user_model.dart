class UserModel {
  final String id;
  final String email;
  final String displayName;
  final bool isProfileComplete;
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final String? biologicalSex;
  final String? experienceLevel;
  final String? primaryGoal;
  final List<String> healthConcerns;
  final String? otherHealthConcern;
  final String? bodyType;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.isProfileComplete = false,
    this.weightKg,
    this.heightCm,
    this.age,
    this.biologicalSex,
    this.experienceLevel,
    this.primaryGoal,
    this.healthConcerns = const [],
    this.otherHealthConcern,
    this.bodyType,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isProfileComplete,
    double? weightKg,
    double? heightCm,
    int? age,
    String? biologicalSex,
    String? experienceLevel,
    String? primaryGoal,
    List<String>? healthConcerns,
    String? otherHealthConcern,
    String? bodyType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      otherHealthConcern: otherHealthConcern ?? this.otherHealthConcern,
      bodyType: bodyType ?? this.bodyType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'is_profile_complete': isProfileComplete,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (age != null) 'age': age,
      if (biologicalSex != null) 'biological_sex': biologicalSex,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (primaryGoal != null) 'primary_goal': primaryGoal,
      'health_concerns': healthConcerns,
      if (otherHealthConcern != null) 'other_health_concern': otherHealthConcern,
      if (bodyType != null) 'body_type': bodyType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Athlete',
      isProfileComplete: map['is_profile_complete'] as bool? ?? false,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      age: (map['age'] as num?)?.toInt(),
      biologicalSex: map['biological_sex'] as String?,
      experienceLevel: map['experience_level'] as String?,
      primaryGoal: map['primary_goal'] as String?,
      healthConcerns: (map['health_concerns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      otherHealthConcern: map['other_health_concern'] as String?,
      bodyType: map['body_type'] as String?,
    );
  }
}
