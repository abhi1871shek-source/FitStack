class WorkoutLoopConfig {
  final String userId;
  final bool isEnabled;
  final int totalCycles;
  final DateTime startWeekMonday;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkoutLoopConfig({
    required this.userId,
    this.isEnabled = false,
    this.totalCycles = 2,
    required this.startWeekMonday,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkoutLoopConfig.fromMap(Map<String, dynamic> map) {
    DateTime parsedMonday;
    if (map['start_week_monday'] != null) {
      parsedMonday = DateTime.parse(map['start_week_monday'].toString());
    } else {
      final now = DateTime.now();
      parsedMonday = now.subtract(Duration(days: now.weekday - 1));
    }
    return WorkoutLoopConfig(
      userId: (map['user_id'] as String?) ?? '',
      isEnabled: (map['is_enabled'] as bool?) ?? false,
      totalCycles: (map['total_cycles'] as int?) ?? 2,
      startWeekMonday: parsedMonday,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final mondayStr = startWeekMonday.toIso8601String().split('T').first;
    return {
      'user_id': userId,
      'is_enabled': isEnabled,
      'total_cycles': totalCycles,
      'start_week_monday': mondayStr,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Calculates the 1-based cycle number for any target date based on full weeks elapsed
  int calculateCycleForDate(DateTime date) {
    if (totalCycles <= 0) return 1;

    final targetMonday = date.subtract(Duration(days: date.weekday - 1));
    final startMonday = DateTime(startWeekMonday.year, startWeekMonday.month, startWeekMonday.day);
    final targetMondayClean = DateTime(targetMonday.year, targetMonday.month, targetMonday.day);

    final daysDiff = targetMondayClean.difference(startMonday).inDays;
    final weeksDiff = (daysDiff / 7.0).floor();

    final cycleIndex = ((weeksDiff % totalCycles) + totalCycles) % totalCycles;
    return cycleIndex + 1; // 1-based cycle number (1..N)
  }

  WorkoutLoopConfig copyWith({
    String? userId,
    bool? isEnabled,
    int? totalCycles,
    DateTime? startWeekMonday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutLoopConfig(
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      totalCycles: totalCycles ?? this.totalCycles,
      startWeekMonday: startWeekMonday ?? this.startWeekMonday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
