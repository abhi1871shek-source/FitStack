class WorkoutCycleExercise {
  final String id;
  final String cycleId;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int targetSets;
  final int targetReps;
  final double targetWeightKg;
  final int sortOrder;
  final DateTime? createdAt;

  const WorkoutCycleExercise({
    required this.id,
    required this.cycleId,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeightKg = 0.0,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory WorkoutCycleExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutCycleExercise(
      id: (map['id'] as String?) ?? '',
      cycleId: (map['cycle_id'] as String?) ?? '',
      exerciseId: (map['exercise_id'] as String?) ?? '',
      exerciseName: (map['exercise_name'] as String?) ?? '',
      muscleGroup: (map['muscle_group'] as String?) ?? 'Chest',
      targetSets: (map['target_sets'] as int?) ?? 3,
      targetReps: (map['target_reps'] as int?) ?? 10,
      targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble() ?? 0.0,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap({required String cycleId}) {
    final data = <String, dynamic>{
      'cycle_id': cycleId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight_kg': targetWeightKg,
      'sort_order': sortOrder,
    };
    if (id.isNotEmpty && !id.startsWith('temp_')) {
      data['id'] = id;
    }
    return data;
  }

  WorkoutCycleExercise copyWith({
    String? id,
    String? cycleId,
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    int? targetSets,
    int? targetReps,
    double? targetWeightKg,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return WorkoutCycleExercise(
      id: id ?? this.id,
      cycleId: cycleId ?? this.cycleId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
