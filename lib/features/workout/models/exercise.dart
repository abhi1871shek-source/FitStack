class Exercise {
  final String id;
  final String name;
  final String muscleGroup; // Chest, Back, Legs, Shoulders, Arms, Core, Cardio
  final int defaultSets;
  final int defaultReps;
  final double defaultWeightKg;
  final List<String> avoidIf; // e.g. ['back_pain'], ['knee_pain'], ['joint_issues']
  final String? imageUrl; // Demonstration illustration/image URL from Free-Exercise-DB
  final bool isHome; // Tagged for bodyweight / home workout filter

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeightKg,
    this.avoidIf = const [],
    this.imageUrl,
    this.isHome = false,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      muscleGroup: map['muscle_group'] as String? ?? 'Full Body',
      defaultSets: map['default_sets'] as int? ?? 3,
      defaultReps: map['default_reps'] as int? ?? 10,
      defaultWeightKg: (map['default_weight_kg'] as num?)?.toDouble() ?? 0.0,
      avoidIf: (map['avoid_if'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      imageUrl: map['image_url'] as String?,
      isHome: map['is_home'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'default_sets': defaultSets,
      'default_reps': defaultReps,
      'default_weight_kg': defaultWeightKg,
      'avoid_if': avoidIf,
      'image_url': imageUrl,
      'is_home': isHome,
    };
  }
}

class WorkoutLogItem {
  final String id;
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weightKg;
  final bool isCompleted;
  final String? imageUrl;

  const WorkoutLogItem({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
    this.imageUrl,
  });

  WorkoutLogItem copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? muscleGroup,
    int? sets,
    int? reps,
    double? weightKg,
    bool? isCompleted,
    String? imageUrl,
  }) {
    return WorkoutLogItem(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory WorkoutLogItem.fromMap(Map<String, dynamic> map) {
    return WorkoutLogItem(
      id: map['id']?.toString() ?? '',
      exerciseId: map['exercise_id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      muscleGroup: map['muscle_group'] as String? ?? 'Full Body',
      sets: map['sets'] as int? ?? 3,
      reps: map['reps'] as int? ?? 10,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      isCompleted: map['is_completed'] as bool? ?? false,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap({required String userId, String? workoutDate}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'exercise_id': exerciseId,
      'name': name,
      'muscle_group': muscleGroup,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'is_completed': isCompleted,
      'image_url': imageUrl,
      'workout_date': workoutDate ?? DateTime.now().toIso8601String().split('T').first,
    };
    if (id.isNotEmpty && !id.startsWith('w_')) {
      map['id'] = id;
    }
    return map;
  }
}
