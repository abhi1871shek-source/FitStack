import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/weekly_plan_day.dart';

class WorkoutWeeklyPlanState {
  final List<WeeklyPlanDay> days;
  final bool isLoading;
  final String? errorMessage;

  const WorkoutWeeklyPlanState({
    this.days = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkoutWeeklyPlanState copyWith({
    List<WeeklyPlanDay>? days,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkoutWeeklyPlanState(
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkoutWeeklyPlanNotifier extends Notifier<WorkoutWeeklyPlanState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  WorkoutWeeklyPlanState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchWeeklyPlan();
      } else {
        state = const WorkoutWeeklyPlanState();
      }
    });

    Future.microtask(() => fetchWeeklyPlan());

    return const WorkoutWeeklyPlanState(isLoading: true);
  }

  Future<void> fetchWeeklyPlan() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const WorkoutWeeklyPlanState(isLoading: false, days: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _client
          .from('weekly_workout_plans')
          .select()
          .eq('user_id', userId)
          .order('day_index', ascending: true);

      final List rows = response as List;
      final now = DateTime.now();
      final todayIndex = now.weekday - 1; // 0=Mon, 6=Sun

      if (rows.isEmpty) {
        // Seed default 7-day plan into Supabase
        final onboarding = ref.read(onboardingProvider);
        final level = onboarding.experienceLevel ?? 'Beginner';
        final goal = onboarding.primaryGoal ?? 'Build Muscle';

        final initialDays = _generateInitialPlan(level, goal);
        final insertList = initialDays.asMap().entries.map((entry) {
          return entry.value.toMap(userId: userId, dayIndex: entry.key);
        }).toList();

        await _client.from('weekly_workout_plans').upsert(
          insertList,
          onConflict: 'user_id, day_index',
        );

        state = WorkoutWeeklyPlanState(
          days: initialDays,
          isLoading: false,
        );
      } else {
        final List<WeeklyPlanDay> days = rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final map = entry.value as Map<String, dynamic>;
          final dbDayIndex = (map['day_index'] as int?) ?? idx;
          final isToday = dbDayIndex == todayIndex;
          return WeeklyPlanDay.fromMap(map, isToday: isToday);
        }).toList();

        state = WorkoutWeeklyPlanState(
          days: days,
          isLoading: false,
        );
      }
    } catch (e, st) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error fetching plan: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load weekly plan from Supabase',
      );
    }
  }

  List<WeeklyPlanDay> _generateInitialPlan(String level, String goal) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final isBeginner = level.toLowerCase() == 'beginner';
    final isMuscleOrWeightGain = goal.toLowerCase().contains('muscle') || goal.toLowerCase().contains('weight gain');

    final List<Map<String, dynamic>> rawSchedule;

    if (isBeginner) {
      rawSchedule = [
        {'title': 'Full Body Workout', 'sub': '4 exercises • 45m • Compound focus', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Hydration protocol • 8h sleep goal', 'rest': true},
        {'title': 'Full Body Workout', 'sub': '4 exercises • 45m • Core & arms focus', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Light walk & mobility stretch', 'rest': true},
        {'title': 'Full Body Workout', 'sub': '4 exercises • 45m • Lifts focus', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Active recovery & foam rolling', 'rest': true},
        {'title': 'Rest & Recovery', 'sub': 'Rest & prepare for upcoming cycle', 'rest': true},
      ];
    } else if (isMuscleOrWeightGain) {
      rawSchedule = [
        {'title': 'Push Day (Chest & Triceps)', 'sub': '4 exercises • 50m • Volume 8,420 kg', 'rest': false},
        {'title': 'Pull Day (Back & Biceps)', 'sub': '5 exercises • 55m • Volume 9,150 kg', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Hydration protocol • 8h sleep goal', 'rest': true},
        {'title': 'Legs & Core', 'sub': '6 exercises • 60m • Barbell Squats', 'rest': false},
        {'title': 'Upper Body Focus', 'sub': '5 exercises • 50m • Hypertrophy focus', 'rest': false},
        {'title': 'Shoulders & Arms', 'sub': '5 exercises • 45m • Overhead Press', 'rest': false},
        {'title': 'Active Recovery & Mobility', 'sub': '30m dynamic stretch & soft-tissue release', 'rest': true},
      ];
    } else {
      rawSchedule = [
        {'title': 'Upper Body (Chest & Back)', 'sub': '5 exercises • 45m • High density', 'rest': false},
        {'title': 'Lower Body & Core', 'sub': '5 exercises • 50m • Squats & abs focus', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Hydration protocol • 8h sleep goal', 'rest': true},
        {'title': 'Push & Pull Focus', 'sub': '5 exercises • 45m • Supersets focus', 'rest': false},
        {'title': 'Legs & Cardio Focus', 'sub': '6 exercises • 50m • HIIT finish', 'rest': false},
        {'title': 'Rest & Recovery', 'sub': 'Rest & active stretch', 'rest': true},
        {'title': 'Active Recovery & Mobility', 'sub': '30m dynamic stretch & mobility', 'rest': true},
      ];
    }

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      final dayDate = monday.add(Duration(days: i));
      final item = rawSchedule[i];
      final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
      final isBeforeToday = dayDate.isBefore(DateTime(now.year, now.month, now.day));
      final isCompleted = isBeforeToday && !(item['rest'] as bool);

      return WeeklyPlanDay(
        dayName: dayNames[i],
        shortName: shortNames[i],
        dateNum: dayDate.day,
        focusTitle: item['title'] as String,
        subtitle: item['sub'] as String,
        isRestDay: item['rest'] as bool,
        isCompleted: isCompleted,
        isToday: isToday,
      );
    });
  }

  Future<void> toggleDayComplete(int index) async {
    final userId = _currentUserId;
    if (userId == null || index < 0 || index >= state.days.length) return;

    final updated = List<WeeklyPlanDay>.from(state.days);
    final current = updated[index];
    final newStatus = !current.isCompleted;
    updated[index] = current.copyWith(isCompleted: newStatus);

    state = state.copyWith(days: updated);

    try {
      await _client
          .from('weekly_workout_plans')
          .update({'is_completed': newStatus})
          .eq('user_id', userId)
          .eq('day_index', index);
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error toggling day complete: $e');
    }
  }

  Future<void> updateDayFocus({
    required int index,
    required String newTitle,
    required bool isRestDay,
    String? customSubtitle,
  }) async {
    final userId = _currentUserId;
    if (userId == null || index < 0 || index >= state.days.length) return;

    final updated = List<WeeklyPlanDay>.from(state.days);
    final current = updated[index];

    final subtitle = customSubtitle ??
        (isRestDay
            ? 'Hydration protocol • 8h sleep goal'
            : 'Scheduled • 5 sets target • Custom focus');

    updated[index] = current.copyWith(
      focusTitle: newTitle,
      isRestDay: isRestDay,
      subtitle: subtitle,
    );

    state = state.copyWith(days: updated);

    try {
      await _client.from('weekly_workout_plans').update({
        'focus_title': newTitle,
        'is_rest_day': isRestDay,
        'subtitle': subtitle,
      }).eq('user_id', userId).eq('day_index', index);
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error updating day focus: $e');
    }
  }
}

final workoutWeeklyPlanProvider = NotifierProvider<WorkoutWeeklyPlanNotifier, WorkoutWeeklyPlanState>(() {
  return WorkoutWeeklyPlanNotifier();
});

/// Convenience provider returning List<WeeklyPlanDay>
final workoutWeeklyPlanListProvider = Provider<List<WeeklyPlanDay>>((ref) {
  return ref.watch(workoutWeeklyPlanProvider).days;
});
