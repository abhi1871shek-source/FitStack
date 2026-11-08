enum DayCounterMode {
  countdown,
  countup;

  String toDb() => name;

  static DayCounterMode fromDb(String val) {
    if (val.toLowerCase() == 'countdown') {
      return DayCounterMode.countdown;
    }
    return DayCounterMode.countup;
  }
}

class DayCounter {
  final String id;
  final String userId;
  final String title;
  final DayCounterMode mode;
  final DateTime startDate;
  final int? targetDays; // null for countup, integer N for countdown
  final DateTime? createdAt;

  const DayCounter({
    required this.id,
    required this.userId,
    required this.title,
    required this.mode,
    required this.startDate,
    this.targetDays,
    this.createdAt,
  });

  /// Parse from Supabase database map
  factory DayCounter.fromMap(Map<String, dynamic> map) {
    final rawDate = map['start_date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null) {
      final str = rawDate.toString().split('T').first;
      final parts = str.split('-');
      if (parts.length == 3) {
        parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } else {
        parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    } else {
      final now = DateTime.now();
      parsedDate = DateTime(now.year, now.month, now.day);
    }
    // Clean to date-only boundary
    parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

    return DayCounter(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Counter',
      mode: DayCounterMode.fromDb(map['mode']?.toString() ?? 'countup'),
      startDate: parsedDate,
      targetDays: map['target_days'] as int?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final y = startDate.year.toString().padLeft(4, '0');
    final m = startDate.month.toString().padLeft(2, '0');
    final d = startDate.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';

    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'mode': mode.toDb(),
      'start_date': dateStr,
      'target_days': mode == DayCounterMode.countdown ? targetDays : null,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  /// Calculates the calendar days elapsed from startDate to today in local date (India/IST boundary)
  int get daysElapsed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    return today.difference(cleanStart).inDays;
  }

  /// Count up: Day = (today - start_date) + 1
  int get countUpDay {
    final elapsed = daysElapsed;
    return elapsed >= 0 ? elapsed + 1 : 1;
  }

  /// Count down: days left = N - (today - start_date). Never negative.
  int get countDownDaysLeft {
    final n = targetDays ?? 0;
    final left = n - daysElapsed;
    return left < 0 ? 0 : left;
  }

  /// Whether a countdown has reached 0
  bool get isCompleted {
    if (mode == DayCounterMode.countdown) {
      final n = targetDays ?? 0;
      return (n - daysElapsed) <= 0;
    }
    return false;
  }

  /// Main value label: "Day X", "Y days left", or "Completed"
  String get displayValue {
    if (mode == DayCounterMode.countup) {
      return 'Day $countUpDay';
    } else {
      final left = countDownDaysLeft;
      if (left == 0) {
        return 'Completed';
      }
      return '$left ${left == 1 ? 'day' : 'days'} left';
    }
  }

  /// Subtitle description
  String get displaySubtitle {
    if (mode == DayCounterMode.countup) {
      final elapsed = daysElapsed;
      if (elapsed == 0) return 'Started today';
      return '$elapsed ${elapsed == 1 ? 'day' : 'days'} elapsed';
    } else {
      final n = targetDays ?? 0;
      if (isCompleted) {
        return '$n-day target completed 🎉';
      }
      final elapsed = daysElapsed;
      return '$n-day target • $elapsed ${elapsed == 1 ? 'day' : 'days'} elapsed';
    }
  }

  DayCounter copyWith({
    String? id,
    String? userId,
    String? title,
    DayCounterMode? mode,
    DateTime? startDate,
    int? targetDays,
    DateTime? createdAt,
  }) {
    return DayCounter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      startDate: startDate ?? this.startDate,
      targetDays: targetDays ?? this.targetDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
