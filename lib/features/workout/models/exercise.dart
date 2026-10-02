import '../data/exercise_library.dart';

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

  bool get isCustom => id.startsWith('ex_custom_');

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

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double weightKg;

  const ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
  });

  ExerciseSet copyWith({
    int? setNumber,
    int? reps,
    double? weightKg,
  }) {
    return ExerciseSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map, int fallbackSetNumber) {
    return ExerciseSet(
      setNumber: (map['set'] as int?) ?? (map['set_number'] as int?) ?? fallbackSetNumber,
      reps: (map['reps'] as int?) ?? 10,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'set': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
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
  final List<ExerciseSet> setDetails;
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
    this.setDetails = const [],
    this.isCompleted = false,
    this.imageUrl,
  });

  int get effectiveSets => setDetails.isNotEmpty ? setDetails.length : sets;

  String? get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    return ExerciseLibrary.getExerciseById(exerciseId)?.imageUrl;
  }

  String get repsAndWeightSummary {
    if (setDetails.isEmpty) {
      final wStr = weightKg == weightKg.roundToDouble() ? weightKg.round().toString() : weightKg.toStringAsFixed(1);
      return '$sets sets × $reps reps • $wStr kg';
    }

    final total = setDetails.length;
    final firstReps = setDetails.first.reps;
    final firstWeight = setDetails.first.weightKg;

    final allSameReps = setDetails.every((s) => s.reps == firstReps);
    final allSameWeight = setDetails.every((s) => s.weightKg == firstWeight);

    if (allSameReps && allSameWeight) {
      final wStr = firstWeight == firstWeight.roundToDouble() ? firstWeight.round().toString() : firstWeight.toStringAsFixed(1);
      return '$total sets × $firstReps reps • $wStr kg';
    }

    // Varying sets
    final weights = setDetails.map((s) => s.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);

    final minWStr = minW == minW.roundToDouble() ? minW.round().toString() : minW.toStringAsFixed(1);
    final maxWStr = maxW == maxW.roundToDouble() ? maxW.round().toString() : maxW.toStringAsFixed(1);

    final repsList = setDetails.map((s) => s.reps).toList();
    final minR = repsList.reduce((a, b) => a < b ? a : b);
    final maxR = repsList.reduce((a, b) => a > b ? a : b);

    final repsStr = (minR == maxR) ? '$minR reps' : '$minR–$maxR reps';
    final weightStr = (minW == maxW) ? '$minWStr kg' : '$minWStr–$maxWStr kg';

    return '$total sets × $repsStr • $weightStr';
  }

  WorkoutLogItem copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? muscleGroup,
    int? sets,
    int? reps,
    double? weightKg,
    List<ExerciseSet>? setDetails,
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
      setDetails: setDetails ?? this.setDetails,
      isCompleted: isCompleted ?? this.isCompleted,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory WorkoutLogItem.fromMap(Map<String, dynamic> map) {
    final rawSets = map['sets'] as int? ?? 3;
    final rawReps = map['reps'] as int? ?? 10;
    final rawWeight = (map['weight_kg'] as num?)?.toDouble() ?? 0.0;

    List<ExerciseSet> parsedSets = [];
    if (map['set_details'] != null && map['set_details'] is List) {
      final list = map['set_details'] as List;
      parsedSets = list.asMap().entries.map((entry) {
        if (entry.value is Map<String, dynamic>) {
          return ExerciseSet.fromMap(entry.value as Map<String, dynamic>, entry.key + 1);
        } else if (entry.value is Map) {
          return ExerciseSet.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key + 1);
        }
        return ExerciseSet(setNumber: entry.key + 1, reps: rawReps, weightKg: rawWeight);
      }).toList();
    }

    if (parsedSets.isEmpty) {
      parsedSets = List.generate(
        rawSets,
        (i) => ExerciseSet(setNumber: i + 1, reps: rawReps, weightKg: rawWeight),
      );
    }

    return WorkoutLogItem(
      id: map['id']?.toString() ?? '',
      exerciseId: map['exercise_id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      muscleGroup: map['muscle_group'] as String? ?? 'Full Body',
      sets: parsedSets.length,
      reps: parsedSets.isNotEmpty ? parsedSets.first.reps : rawReps,
      weightKg: parsedSets.isNotEmpty ? parsedSets.first.weightKg : rawWeight,
      setDetails: parsedSets,
      isCompleted: map['is_completed'] as bool? ?? false,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap({required String userId, String? workoutDate}) {
    final effectiveSetsList = setDetails.isNotEmpty
        ? setDetails
        : List.generate(sets, (i) => ExerciseSet(setNumber: i + 1, reps: reps, weightKg: weightKg));

    final map = <String, dynamic>{
      'user_id': userId,
      'exercise_id': exerciseId,
      'name': name,
      'muscle_group': muscleGroup,
      'sets': effectiveSetsList.length,
      'reps': effectiveSetsList.isNotEmpty ? effectiveSetsList.first.reps : reps,
      'weight_kg': effectiveSetsList.isNotEmpty ? effectiveSetsList.first.weightKg : weightKg,
      'set_details': effectiveSetsList.map((s) => s.toMap()).toList(),
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
