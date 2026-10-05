import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../onboarding/providers/onboarding_provider.dart';
import '../models/exercise.dart';
import '../models/weekly_plan_day.dart';
import '../models/workout_cycle_exercise.dart';
import '../models/workout_loop_config.dart';

class WorkoutWeeklyPlanState {
  final List<WeeklyPlanDay> days;
  final bool isLoopEnabled;
  final int totalCycles;
  final int activeCycleNumber;
  final int viewingCycleNumber;
  final WorkoutLoopConfig? loopConfig;
  final Map<int, List<WeeklyPlanDay>> cycleDaysMap;
  final Map<String, List<WorkoutCycleExercise>> cycleExercisesMap;
  final bool isLoading;
  final String? errorMessage;

  const WorkoutWeeklyPlanState({
    this.days = const [],
    this.isLoopEnabled = false,
    this.totalCycles = 2,
    this.activeCycleNumber = 1,
    this.viewingCycleNumber = 1,
    this.loopConfig,
    this.cycleDaysMap = const {},
    this.cycleExercisesMap = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  WorkoutWeeklyPlanState copyWith({
    List<WeeklyPlanDay>? days,
    bool? isLoopEnabled,
    int? totalCycles,
    int? activeCycleNumber,
    int? viewingCycleNumber,
    WorkoutLoopConfig? loopConfig,
    Map<int, List<WeeklyPlanDay>>? cycleDaysMap,
    Map<String, List<WorkoutCycleExercise>>? cycleExercisesMap,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkoutWeeklyPlanState(
      days: days ?? this.days,
      isLoopEnabled: isLoopEnabled ?? this.isLoopEnabled,
      totalCycles: totalCycles ?? this.totalCycles,
      activeCycleNumber: activeCycleNumber ?? this.activeCycleNumber,
      viewingCycleNumber: viewingCycleNumber ?? this.viewingCycleNumber,
      loopConfig: loopConfig ?? this.loopConfig,
      cycleDaysMap: cycleDaysMap ?? this.cycleDaysMap,
      cycleExercisesMap: cycleExercisesMap ?? this.cycleExercisesMap,
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
      // 1. Fetch Loop Config from Supabase
      WorkoutLoopConfig? config;
      try {
        final configResp = await _client
            .from('workout_loop_config')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (configResp != null) {
          config = WorkoutLoopConfig.fromMap(configResp as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('[WorkoutWeeklyPlanNotifier] Loop config table check: $e');
      }

      final now = DateTime.now();
      final todayIndex = now.weekday - 1; // 0=Mon, 6=Sun

      final isLoopON = config?.isEnabled ?? false;
      final totalCycles = config?.totalCycles ?? 2;
      final activeCycleNum = config != null ? config.calculateCycleForDate(now) : 1;
      final viewingCycleNum = state.viewingCycleNumber > totalCycles ? 1 : state.viewingCycleNumber;

      if (isLoopON) {
        // Fetch cycle data
        await _fetchAndBuildCycleData(
          userId: userId,
          config: config!,
          activeCycleNum: activeCycleNum,
          viewingCycleNum: viewingCycleNum,
          todayIndex: todayIndex,
        );
      } else {
        // Single week plan mode
        final response = await _client
            .from('weekly_workout_plans')
            .select()
            .eq('user_id', userId)
            .order('day_index', ascending: true);

        final List rows = response as List;

        if (rows.isEmpty) {
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
            isLoopEnabled: false,
            totalCycles: totalCycles,
            activeCycleNumber: 1,
            viewingCycleNumber: 1,
            loopConfig: config,
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
            isLoopEnabled: false,
            totalCycles: totalCycles,
            activeCycleNumber: 1,
            viewingCycleNumber: 1,
            loopConfig: config,
            isLoading: false,
          );
        }
      }
    } catch (e, st) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error fetching plan: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load weekly plan from Supabase',
      );
    }
  }

  Future<void> _fetchAndBuildCycleData({
    required String userId,
    required WorkoutLoopConfig config,
    required int activeCycleNum,
    required int viewingCycleNum,
    required int todayIndex,
  }) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // 1. Fetch workout_cycles for this user
    final cycleRowsResp = await _client
        .from('workout_cycles')
        .select()
        .eq('user_id', userId)
        .order('cycle_number', ascending: true)
        .order('day_index', ascending: true);

    final List cycleRows = cycleRowsResp as List;

    // 2. Fetch workout_cycle_exercises for all cycle days of this user
    final exerciseRowsResp = await _client
        .from('workout_cycle_exercises')
        .select('*, workout_cycles!inner(user_id, cycle_number, day_index)')
        .eq('workout_cycles.user_id', userId);

    final List exerciseRows = exerciseRowsResp as List;

    final Map<String, List<WorkoutCycleExercise>> cycleExercisesMap = {};
    for (final row in exerciseRows) {
      final map = row as Map<String, dynamic>;
      final cycleInfo = map['workout_cycles'] as Map<String, dynamic>?;
      if (cycleInfo != null) {
        final cNum = cycleInfo['cycle_number'] as int;
        final dIdx = cycleInfo['day_index'] as int;
        final key = '${cNum}_$dIdx';
        final exItem = WorkoutCycleExercise.fromMap(map);
        cycleExercisesMap.putIfAbsent(key, () => []).add(exItem);
      }
    }

    final Map<int, List<WeeklyPlanDay>> cycleDaysMap = {};

    for (int c = 1; c <= config.totalCycles; c++) {
      final List<WeeklyPlanDay> cDays = [];
      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;

        final matchingRow = cycleRows.firstWhere(
          (r) => r['cycle_number'] == c && r['day_index'] == i,
          orElse: () => null,
        );

        final key = '${c}_$i';
        final exList = cycleExercisesMap[key] ?? [];

        String focusTitle;
        String subtitle;
        bool isRestDay;

        if (matchingRow != null) {
          focusTitle = matchingRow['focus_title'] ?? 'Full Body';
          isRestDay = matchingRow['is_rest_day'] ?? false;
          subtitle = matchingRow['subtitle'] ?? '';
          if (subtitle.isEmpty && exList.isNotEmpty) {
            subtitle = '${exList.length} exercises • Custom Loop';
          } else if (subtitle.isEmpty) {
            subtitle = isRestDay ? 'Rest & Recovery' : 'Scheduled • Loop Cycle $c';
          }
        } else {
          // Default fallbacks per cycle
          isRestDay = (i == 2 || i == 6);
          focusTitle = isRestDay
              ? 'Rest & Recovery'
              : (c == 1
                  ? (i == 0 ? 'Push Day (Chest & Triceps)' : i == 1 ? 'Pull Day (Back & Biceps)' : 'Legs & Core')
                  : (i == 0 ? 'Upper Body Heavy' : i == 1 ? 'Lower Body Power' : 'Full Body Hypertrophy'));
          subtitle = isRestDay ? 'Hydration protocol' : 'Loop Cycle $c Template';
        }

        cDays.add(WeeklyPlanDay(
          dayName: dayNames[i],
          shortName: shortNames[i],
          dateNum: dayDate.day,
          focusTitle: focusTitle,
          subtitle: subtitle,
          isRestDay: isRestDay,
          isCompleted: isToday ? false : false,
          isToday: isToday && (c == activeCycleNum),
        ));
      }
      cycleDaysMap[c] = cDays;
    }

    // Determine displayed days list (show viewing cycle if viewing, or active cycle)
    final displayedDays = cycleDaysMap[viewingCycleNum] ?? cycleDaysMap[activeCycleNum] ?? [];

    state = WorkoutWeeklyPlanState(
      days: displayedDays,
      isLoopEnabled: true,
      totalCycles: config.totalCycles,
      activeCycleNumber: activeCycleNum,
      viewingCycleNumber: viewingCycleNum,
      loopConfig: config,
      cycleDaysMap: cycleDaysMap,
      cycleExercisesMap: cycleExercisesMap,
      isLoading: false,
    );
  }

  /// Toggle Loop ON/OFF
  Future<void> toggleLoop(bool enable) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    if (enable) {
      // 1. Create or update loop config
      final newConfig = WorkoutLoopConfig(
        userId: userId,
        isEnabled: true,
        totalCycles: state.totalCycles > 0 ? state.totalCycles : 2,
        startWeekMonday: monday,
      );

      try {
        await _client.from('workout_loop_config').upsert(newConfig.toMap(), onConflict: 'user_id');
      } catch (e) {
        debugPrint('[WorkoutWeeklyPlanNotifier] Error updating loop config: $e');
      }

      // 2. Ensure default 2 cycles exist in workout_cycles if missing
      await _seedDefaultCyclesIfMissing(userId, newConfig.totalCycles);

      // Re-fetch
      await fetchWeeklyPlan();
    } else {
      // Turning Loop OFF:
      // 1. Copy active cycle's schedule into weekly_workout_plans so user retains continuity!
      try {
        final activeCycleNum = state.activeCycleNumber;
        final currentActiveDays = state.cycleDaysMap[activeCycleNum] ?? state.days;

        if (currentActiveDays.isNotEmpty) {
          final insertList = currentActiveDays.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;
            return {
              'user_id': userId,
              'day_index': idx,
              'day_name': day.dayName,
              'short_name': day.shortName,
              'date_num': day.dateNum,
              'focus_title': day.focusTitle,
              'subtitle': day.subtitle,
              'is_rest_day': day.isRestDay,
              'is_completed': false,
            };
          }).toList();

          await _client.from('weekly_workout_plans').upsert(insertList, onConflict: 'user_id, day_index');
        }

        // 2. Disable loop config
        await _client.from('workout_loop_config').upsert({
          'user_id': userId,
          'is_enabled': false,
          'total_cycles': state.totalCycles,
          'start_week_monday': monday.toIso8601String().split('T').first,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('[WorkoutWeeklyPlanNotifier] Error disabling loop: $e');
      }

      await fetchWeeklyPlan();
    }
  }

  /// Change total cycle count (e.g. 2 -> 3 or 4)
  Future<void> setTotalCycles(int count) async {
    final userId = _currentUserId;
    if (userId == null || count < 2) return;

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final updatedConfig = WorkoutLoopConfig(
      userId: userId,
      isEnabled: state.isLoopEnabled,
      totalCycles: count,
      startWeekMonday: state.loopConfig?.startWeekMonday ?? monday,
    );

    try {
      await _client.from('workout_loop_config').upsert(updatedConfig.toMap(), onConflict: 'user_id');
      await _seedDefaultCyclesIfMissing(userId, count);
      await fetchWeeklyPlan();
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error updating total cycles: $e');
    }
  }

  /// Switch the cycle tab being viewed in the Weekly Plan UI
  void selectViewingCycle(int cycleNum) {
    if (!state.isLoopEnabled) return;
    final cycleDays = state.cycleDaysMap[cycleNum] ?? [];
    state = state.copyWith(
      viewingCycleNumber: cycleNum,
      days: cycleDays,
    );
  }

  /// Seed default cycles in Supabase if empty for user
  Future<void> _seedDefaultCyclesIfMissing(String userId, int totalCycles) async {
    try {
      final existing = await _client
          .from('workout_cycles')
          .select('id, cycle_number, day_index')
          .eq('user_id', userId);

      final List existingList = existing as List;

      final onboarding = ref.read(onboardingProvider);
      final level = onboarding.experienceLevel ?? 'Beginner';
      final goal = onboarding.primaryGoal ?? 'Build Muscle';
      final defaultPlan = _generateInitialPlan(level, goal);

      final List<Map<String, dynamic>> cyclesToInsert = [];

      for (int c = 1; c <= totalCycles; c++) {
        for (int d = 0; d < 7; d++) {
          final match = existingList.firstWhere(
            (e) => e['cycle_number'] == c && e['day_index'] == d,
            orElse: () => null,
          );
          if (match == null) {
            final templateDay = defaultPlan[d];
            final title = (c == 1)
                ? templateDay.focusTitle
                : (templateDay.isRestDay ? 'Rest & Recovery' : '${templateDay.focusTitle} (Cycle $c Variant)');
            cyclesToInsert.add({
              'user_id': userId,
              'cycle_number': c,
              'day_index': d,
              'focus_title': title,
              'subtitle': templateDay.subtitle,
              'is_rest_day': templateDay.isRestDay,
            });
          }
        }
      }

      if (cyclesToInsert.isNotEmpty) {
        await _client.from('workout_cycles').upsert(
          cyclesToInsert,
          onConflict: 'user_id, cycle_number, day_index',
        );
      }
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error seeding default cycles: $e');
    }
  }

  /// Update Focus Title or Rest status for a specific cycle day
  Future<void> updateCycleDayFocus({
    required int cycleNumber,
    required int dayIndex,
    required String newTitle,
    required bool isRestDay,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Upsert into workout_cycles
      await _client.from('workout_cycles').upsert({
        'user_id': userId,
        'cycle_number': cycleNumber,
        'day_index': dayIndex,
        'focus_title': newTitle,
        'is_rest_day': isRestDay,
        'subtitle': isRestDay ? 'Hydration protocol' : 'Custom Focus • Cycle $cycleNumber',
      }, onConflict: 'user_id, cycle_number, day_index');

      await fetchWeeklyPlan();
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error updating cycle day focus: $e');
    }
  }

  /// Update exercises for a cycle day
  Future<void> saveExercisesForCycleDay({
    required int cycleNumber,
    required int dayIndex,
    required List<Exercise> selectedExercises,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // 1. Ensure cycle row exists
      final cycleResp = await _client.from('workout_cycles').upsert({
        'user_id': userId,
        'cycle_number': cycleNumber,
        'day_index': dayIndex,
        'focus_title': selectedExercises.isNotEmpty ? '${selectedExercises.first.muscleGroup} Focus' : 'Full Body',
        'is_rest_day': false,
        'subtitle': '${selectedExercises.length} exercises • Cycle $cycleNumber',
      }, onConflict: 'user_id, cycle_number, day_index').select().single();

      final cycleId = cycleResp['id'] as String;

      // 2. Delete existing cycle exercises for this cycle_id
      await _client.from('workout_cycle_exercises').delete().eq('cycle_id', cycleId);

      // 3. Insert new exercises
      if (selectedExercises.isNotEmpty) {
        final insertList = selectedExercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final ex = entry.value;
          return {
            'cycle_id': cycleId,
            'exercise_id': ex.id,
            'exercise_name': ex.name,
            'muscle_group': ex.muscleGroup,
            'target_sets': ex.defaultSets,
            'target_reps': ex.defaultReps,
            'target_weight_kg': ex.defaultWeightKg,
            'sort_order': idx,
          };
        }).toList();

        await _client.from('workout_cycle_exercises').insert(insertList);
      }

      await fetchWeeklyPlan();
    } catch (e) {
      debugPrint('[WorkoutWeeklyPlanNotifier] Error saving cycle exercises: $e');
    }
  }

  /// Update single non-loop weekly plan day (when Loop is OFF)
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
}

final workoutWeeklyPlanProvider = NotifierProvider<WorkoutWeeklyPlanNotifier, WorkoutWeeklyPlanState>(() {
  return WorkoutWeeklyPlanNotifier();
});

/// Convenience provider returning List<WeeklyPlanDay>
final workoutWeeklyPlanListProvider = Provider<List<WeeklyPlanDay>>((ref) {
  return ref.watch(workoutWeeklyPlanProvider).days;
});
