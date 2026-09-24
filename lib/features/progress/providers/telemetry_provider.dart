import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/telemetry_data.dart';

class TelemetryState {
  final TelemetryData? todayTelemetry;
  final List<TelemetryData> historicalTelemetry;
  final bool isLoading;
  final String? errorMessage;

  const TelemetryState({
    this.todayTelemetry,
    this.historicalTelemetry = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TelemetryState copyWith({
    TelemetryData? todayTelemetry,
    List<TelemetryData>? historicalTelemetry,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TelemetryState(
      todayTelemetry: todayTelemetry ?? this.todayTelemetry,
      historicalTelemetry: historicalTelemetry ?? this.historicalTelemetry,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TelemetryNotifier extends Notifier<TelemetryState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  TelemetryState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchTelemetry();
      } else {
        state = const TelemetryState();
      }
    });

    Future.microtask(() => fetchTelemetry());

    return const TelemetryState(isLoading: true);
  }

  /// Load today's daily telemetry and historical telemetry rows from Supabase
  Future<void> fetchTelemetry() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const TelemetryState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    try {
      // 1. Fetch today's telemetry
      final response = await _client
          .from('daily_telemetry')
          .select()
          .eq('user_id', userId)
          .eq('log_date', todayStr)
          .maybeSingle();

      TelemetryData todayData;
      if (response != null) {
        todayData = TelemetryData.fromMap(response);
      } else {
        // Initialize today telemetry row if missing
        todayData = TelemetryData(
          logDate: todayStr,
          stepCount: 6240, // default initial steps
          habitsCompleted: 0,
          habitsTotal: 0,
          exercisesCompleted: 0,
          exercisesTotal: 0,
          caloriesConsumed: 0,
          calorieTarget: 2000,
        );
      }

      // 2. Fetch past 30 days telemetry for history
      final thirtyDaysAgoStr = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String()
          .split('T')
          .first;

      final historyResponse = await _client
          .from('daily_telemetry')
          .select()
          .eq('user_id', userId)
          .gte('log_date', thirtyDaysAgoStr)
          .order('log_date', ascending: true);

      final List<TelemetryData> history = (historyResponse as List)
          .map((row) => TelemetryData.fromMap(row))
          .toList();

      state = TelemetryState(
        todayTelemetry: todayData,
        historicalTelemetry: history,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e, st) {
      debugPrint('[TelemetryNotifier] Error fetching telemetry: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load telemetry data from Supabase',
      );
    }
  }

  /// Save or update step count and upsert to daily_telemetry
  Future<void> updateSteps(int steps) async {
    final userId = _currentUserId;
    final current = state.todayTelemetry ??
        TelemetryData(
          logDate: DateTime.now().toIso8601String().split('T').first,
          stepCount: steps,
          habitsCompleted: 0,
          habitsTotal: 0,
          exercisesCompleted: 0,
          exercisesTotal: 0,
          caloriesConsumed: 0,
          calorieTarget: 2000,
        );

    final updated = current.copyWith(stepCount: steps);
    state = state.copyWith(todayTelemetry: updated);

    if (userId == null) return;

    try {
      await _client
          .from('daily_telemetry')
          .upsert(updated.toMap(userId: userId), onConflict: 'user_id,log_date');
      debugPrint('[TelemetryNotifier] Updated steps to $steps in Supabase daily_telemetry');
    } catch (e) {
      debugPrint('[TelemetryNotifier] Error updating steps: $e');
    }
  }

  /// Sync today's activity metrics (habits, exercises, calories) to daily_telemetry
  Future<void> syncTodayActivity({
    int? habitsCompleted,
    int? habitsTotal,
    int? exercisesCompleted,
    int? exercisesTotal,
    double? caloriesConsumed,
    int? calorieTarget,
  }) async {
    final userId = _currentUserId;
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final current = state.todayTelemetry ??
        TelemetryData(
          logDate: todayStr,
          stepCount: 6240,
          habitsCompleted: 0,
          habitsTotal: 0,
          exercisesCompleted: 0,
          exercisesTotal: 0,
          caloriesConsumed: 0,
          calorieTarget: 2000,
        );

    final updated = current.copyWith(
      habitsCompleted: habitsCompleted ?? current.habitsCompleted,
      habitsTotal: habitsTotal ?? current.habitsTotal,
      exercisesCompleted: exercisesCompleted ?? current.exercisesCompleted,
      exercisesTotal: exercisesTotal ?? current.exercisesTotal,
      caloriesConsumed: caloriesConsumed ?? current.caloriesConsumed,
      calorieTarget: calorieTarget ?? current.calorieTarget,
    );

    state = state.copyWith(todayTelemetry: updated);

    if (userId == null) return;

    try {
      await _client
          .from('daily_telemetry')
          .upsert(updated.toMap(userId: userId), onConflict: 'user_id,log_date');
    } catch (e) {
      debugPrint('[TelemetryNotifier] Error syncing daily_telemetry: $e');
    }
  }
}

final telemetryNotifierProvider =
    NotifierProvider<TelemetryNotifier, TelemetryState>(() {
  return TelemetryNotifier();
});

final todayTelemetryProvider = Provider<TelemetryData?>((ref) {
  return ref.watch(telemetryNotifierProvider).todayTelemetry;
});

final historicalTelemetryProvider = Provider<List<TelemetryData>>((ref) {
  return ref.watch(telemetryNotifierProvider).historicalTelemetry;
});
