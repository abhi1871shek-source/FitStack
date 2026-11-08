import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/day_counter.dart';

class DayCountersState {
  final List<DayCounter> counters;
  final bool isLoading;
  final String? errorMessage;

  const DayCountersState({
    this.counters = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DayCountersState copyWith({
    List<DayCounter>? counters,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DayCountersState(
      counters: counters ?? this.counters,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DayCountersNotifier extends Notifier<DayCountersState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  DayCountersState build() {
    loadCounters();
    return const DayCountersState(isLoading: true);
  }

  /// Load all day counters for the current user
  Future<void> loadCounters() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = state.copyWith(isLoading: false, counters: []);
      return;
    }

    try {
      final response = await _client
          .from('day_counters')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final List rows = response as List;
      final list = rows.map((r) => DayCounter.fromMap(r as Map<String, dynamic>)).toList();

      state = state.copyWith(
        counters: list,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('[DayCountersNotifier] Error loading counters: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load day counters: $e',
      );
    }
  }

  /// Create a new counter
  Future<DayCounter?> addCounter({
    required String title,
    required DayCounterMode mode,
    required DateTime startDate,
    int? targetDays,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);

    final newCounter = DayCounter(
      id: '',
      userId: userId,
      title: title.trim(),
      mode: mode,
      startDate: cleanStart,
      targetDays: mode == DayCounterMode.countdown ? targetDays : null,
      createdAt: DateTime.now(),
    );

    try {
      final insertMap = newCounter.toMap(includeId: false);
      final resp = await _client.from('day_counters').insert(insertMap).select().single();

      final created = DayCounter.fromMap(resp);
      state = state.copyWith(
        counters: [...state.counters, created],
        errorMessage: null,
      );
      return created;
    } catch (e) {
      debugPrint('[DayCountersNotifier] Error adding counter: $e');
      state = state.copyWith(errorMessage: 'Failed to add counter: $e');
      return null;
    }
  }

  /// Update an existing counter
  Future<bool> updateCounter({
    required String id,
    required String title,
    required DayCounterMode mode,
    required DateTime startDate,
    int? targetDays,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final prevCounters = List<DayCounter>.from(state.counters);

    final updated = DayCounter(
      id: id,
      userId: userId,
      title: title.trim(),
      mode: mode,
      startDate: cleanStart,
      targetDays: mode == DayCounterMode.countdown ? targetDays : null,
    );

    // Optimistic update
    state = state.copyWith(
      counters: state.counters.map((c) => c.id == id ? updated : c).toList(),
    );

    try {
      await _client
          .from('day_counters')
          .update(updated.toMap(includeId: false))
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('[DayCountersNotifier] Error updating counter: $e');
      state = state.copyWith(counters: prevCounters, errorMessage: 'Failed to update: $e');
      return false;
    }
  }

  /// Reset counter start date back to today
  Future<bool> resetCounter(String id) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final y = today.year.toString().padLeft(4, '0');
    final m = today.month.toString().padLeft(2, '0');
    final d = today.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';

    final prevCounters = List<DayCounter>.from(state.counters);

    // Optimistic update
    state = state.copyWith(
      counters: state.counters.map((c) => c.id == id ? c.copyWith(startDate: today) : c).toList(),
    );

    try {
      await _client
          .from('day_counters')
          .update({'start_date': dateStr})
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('[DayCountersNotifier] Error resetting counter: $e');
      state = state.copyWith(counters: prevCounters, errorMessage: 'Failed to reset: $e');
      return false;
    }
  }

  /// Delete a counter
  Future<bool> deleteCounter(String id) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final prevCounters = List<DayCounter>.from(state.counters);
    state = state.copyWith(
      counters: state.counters.where((c) => c.id != id).toList(),
    );

    try {
      await _client.from('day_counters').delete().eq('id', id).eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('[DayCountersNotifier] Error deleting counter: $e');
      state = state.copyWith(counters: prevCounters, errorMessage: 'Failed to delete: $e');
      return false;
    }
  }
}

final dayCountersProvider = NotifierProvider<DayCountersNotifier, DayCountersState>(DayCountersNotifier.new);
