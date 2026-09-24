class WeeklyPlanDay {
  final String dayName; // 'Monday', 'Tuesday', etc.
  final String shortName; // 'Mon', 'Tue', etc.
  final int dateNum; // Day of month number
  final String focusTitle; // 'Push Day (Chest & Triceps)', 'Rest & Recovery', etc.
  final String subtitle; // Details microcopy
  final bool isRestDay;
  final bool isCompleted;
  final bool isToday;

  const WeeklyPlanDay({
    required this.dayName,
    required this.shortName,
    required this.dateNum,
    required this.focusTitle,
    required this.subtitle,
    this.isRestDay = false,
    this.isCompleted = false,
    this.isToday = false,
  });

  WeeklyPlanDay copyWith({
    String? dayName,
    String? shortName,
    int? dateNum,
    String? focusTitle,
    String? subtitle,
    bool? isRestDay,
    bool? isCompleted,
    bool? isToday,
  }) {
    return WeeklyPlanDay(
      dayName: dayName ?? this.dayName,
      shortName: shortName ?? this.shortName,
      dateNum: dateNum ?? this.dateNum,
      focusTitle: focusTitle ?? this.focusTitle,
      subtitle: subtitle ?? this.subtitle,
      isRestDay: isRestDay ?? this.isRestDay,
      isCompleted: isCompleted ?? this.isCompleted,
      isToday: isToday ?? this.isToday,
    );
  }

  factory WeeklyPlanDay.fromMap(Map<String, dynamic> map, {bool isToday = false}) {
    return WeeklyPlanDay(
      dayName: map['day_name'] as String? ?? 'Monday',
      shortName: map['short_name'] as String? ?? 'Mon',
      dateNum: map['date_num'] as int? ?? DateTime.now().day,
      focusTitle: map['focus_title'] as String? ?? 'Workout Day',
      subtitle: map['subtitle'] as String? ?? '',
      isRestDay: map['is_rest_day'] as bool? ?? false,
      isCompleted: map['is_completed'] as bool? ?? false,
      isToday: isToday,
    );
  }

  Map<String, dynamic> toMap({required String userId, required int dayIndex}) {
    return {
      'user_id': userId,
      'day_name': dayName,
      'short_name': shortName,
      'day_index': dayIndex,
      'date_num': dateNum,
      'focus_title': focusTitle,
      'subtitle': subtitle,
      'is_rest_day': isRestDay,
      'is_completed': isCompleted,
    };
  }
}
