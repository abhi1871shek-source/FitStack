class HabitItem {
  final String id;
  final String title;
  final String timeOfDay; // 'Morning', 'Afternoon', 'Evening'
  final String category; // 'Workout', 'Nutrition', 'Habits', 'Routine'
  final String? time; // e.g. '2:30 PM'
  final String? subtitle; // e.g. '3,000 steps' or '55 mins'
  final bool isCompleted;
  final int streakDays;
  final int? reminderMinutesBefore; // 5, 10, or null
  final int? scheduledHour; // 0..23
  final int? scheduledMinute; // 0..59
  final bool isRecurring;
  final DateTime? createdAt;

  const HabitItem({
    required this.id,
    required this.title,
    this.timeOfDay = 'Morning',
    required this.category,
    this.time,
    this.subtitle,
    this.isCompleted = false,
    this.streakDays = 0,
    this.reminderMinutesBefore,
    this.scheduledHour,
    this.scheduledMinute,
    this.isRecurring = true,
    this.createdAt,
  });

  HabitItem copyWith({
    String? id,
    String? title,
    String? timeOfDay,
    String? category,
    String? time,
    String? subtitle,
    bool? isCompleted,
    int? streakDays,
    int? reminderMinutesBefore,
    int? scheduledHour,
    int? scheduledMinute,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      category: category ?? this.category,
      time: time ?? this.time,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      streakDays: streakDays ?? this.streakDays,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HabitItem.fromMap(Map<String, dynamic> map, {bool isCompletedToday = false}) {
    DateTime? parsedCreatedAt;
    if (map['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(map['created_at'].toString())?.toLocal();
    }

    return HabitItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      timeOfDay: map['time_of_day'] as String? ?? 'Morning',
      category: map['category'] as String? ?? 'Routine',
      time: map['scheduled_time'] as String?,
      subtitle: map['subtitle'] as String?,
      isCompleted: isCompletedToday || (map['is_completed'] as bool? ?? false),
      streakDays: map['streak_days'] as int? ?? 0,
      reminderMinutesBefore: map['reminder_minutes_before'] as int?,
      scheduledHour: map['scheduled_hour'] as int?,
      scheduledMinute: map['scheduled_minute'] as int?,
      isRecurring: map['is_recurring'] as bool? ?? true,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'time_of_day': timeOfDay,
      'category': category,
      'scheduled_time': time,
      'subtitle': subtitle,
      'is_completed': isCompleted,
      'streak_days': streakDays,
      'reminder_minutes_before': reminderMinutesBefore,
      'scheduled_hour': scheduledHour,
      'scheduled_minute': scheduledMinute,
      'is_recurring': isRecurring,
    };
    if (createdAt != null) {
      map['created_at'] = createdAt!.toUtc().toIso8601String();
    }
    if (id.isNotEmpty && !id.startsWith('h_')) {
      map['id'] = id;
    }
    return map;
  }
}


