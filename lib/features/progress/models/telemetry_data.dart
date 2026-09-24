class TelemetryData {
  final String? id;
  final String? userId;
  final String logDate; // e.g. '2026-09-16'
  final int stepCount;
  final int stepGoal;
  final int habitsCompleted;
  final int habitsTotal;
  final int exercisesCompleted;
  final int exercisesTotal;
  final double caloriesConsumed;
  final int calorieTarget;

  const TelemetryData({
    this.id,
    this.userId,
    required this.logDate,
    required this.stepCount,
    this.stepGoal = 10000,
    required this.habitsCompleted,
    required this.habitsTotal,
    required this.exercisesCompleted,
    required this.exercisesTotal,
    required this.caloriesConsumed,
    required this.calorieTarget,
  });

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      logDate: map['log_date']?.toString() ??
          DateTime.now().toIso8601String().split('T').first,
      stepCount: (map['step_count'] as num?)?.toInt() ?? 0,
      habitsCompleted: (map['habits_completed'] as num?)?.toInt() ?? 0,
      habitsTotal: (map['habits_total'] as num?)?.toInt() ?? 0,
      exercisesCompleted: (map['exercises_completed'] as num?)?.toInt() ?? 0,
      exercisesTotal: (map['exercises_total'] as num?)?.toInt() ?? 0,
      caloriesConsumed: (map['calories_consumed'] as num?)?.toDouble() ?? 0.0,
      calorieTarget: (map['calorie_target'] as num?)?.toInt() ?? 2000,
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    final data = <String, dynamic>{
      'user_id': userId,
      'log_date': logDate,
      'step_count': stepCount,
      'habits_completed': habitsCompleted,
      'habits_total': habitsTotal,
      'exercises_completed': exercisesCompleted,
      'exercises_total': exercisesTotal,
      'calories_consumed': caloriesConsumed,
      'calorie_target': calorieTarget,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  TelemetryData copyWith({
    String? id,
    String? userId,
    String? logDate,
    int? stepCount,
    int? stepGoal,
    int? habitsCompleted,
    int? habitsTotal,
    int? exercisesCompleted,
    int? exercisesTotal,
    double? caloriesConsumed,
    int? calorieTarget,
  }) {
    return TelemetryData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      stepCount: stepCount ?? this.stepCount,
      stepGoal: stepGoal ?? this.stepGoal,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
      exercisesTotal: exercisesTotal ?? this.exercisesTotal,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      calorieTarget: calorieTarget ?? this.calorieTarget,
    );
  }

  double get stepProgress =>
      stepGoal > 0 ? (stepCount / stepGoal).clamp(0.0, 1.0) : 0.0;
  double get calorieProgress =>
      calorieTarget > 0 ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.0) : 0.0;
  double get habitsProgress =>
      habitsTotal > 0 ? (habitsCompleted / habitsTotal).clamp(0.0, 1.0) : 0.0;
  double get exercisesProgress =>
      exercisesTotal > 0 ? (exercisesCompleted / exercisesTotal).clamp(0.0, 1.0) : 0.0;
  double get overallScore =>
      (habitsProgress + exercisesProgress + calorieProgress) / 3.0;
}
