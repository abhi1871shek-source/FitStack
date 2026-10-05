import 'workout_cycle_exercise.dart';

class WorkoutCycleDay {
  final String id;
  final String userId;
  final int cycleNumber; // 1, 2, 3...
  final int dayIndex; // 0=Mon ... 6=Sun
  final String focusTitle;
  final String subtitle;
  final bool isRestDay;
  final List<WorkoutCycleExercise> exercises;

  const WorkoutCycleDay({
    required this.id,
    required this.userId,
    required this.cycleNumber,
    required this.dayIndex,
    required this.focusTitle,
    this.subtitle = '',
    this.isRestDay = false,
    this.exercises = const [],
  });

  factory WorkoutCycleDay.fromMap(Map<String, dynamic> map, {List<WorkoutCycleExercise> exercises = const []}) {
    return WorkoutCycleDay(
      id: (map['id'] as String?) ?? '',
      userId: (map['user_id'] as String?) ?? '',
      cycleNumber: (map['cycle_number'] as int?) ?? 1,
      dayIndex: (map['day_index'] as int?) ?? 0,
      focusTitle: (map['focus_title'] as String?) ?? 'Full Body',
      subtitle: (map['subtitle'] as String?) ?? '',
      isRestDay: (map['is_rest_day'] as bool?) ?? false,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    final data = <String, dynamic>{
      'user_id': userId,
      'cycle_number': cycleNumber,
      'day_index': dayIndex,
      'focus_title': focusTitle,
      'subtitle': subtitle,
      'is_rest_day': isRestDay,
    };
    if (id.isNotEmpty && !id.startsWith('temp_')) {
      data['id'] = id;
    }
    return data;
  }

  WorkoutCycleDay copyWith({
    String? id,
    String? userId,
    int? cycleNumber,
    int? dayIndex,
    String? focusTitle,
    String? subtitle,
    bool? isRestDay,
    List<WorkoutCycleExercise>? exercises,
  }) {
    return WorkoutCycleDay(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      dayIndex: dayIndex ?? this.dayIndex,
      focusTitle: focusTitle ?? this.focusTitle,
      subtitle: subtitle ?? this.subtitle,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }
}
