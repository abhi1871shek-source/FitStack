import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../models/habit_item.dart';

class HabitsState {
  final List<HabitItem> habits;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedDate;
  final Set<String> completedDatesWithHabits;

  HabitsState({
    this.habits = const [],
    this.isLoading = false,
    this.errorMessage,
    DateTime? selectedDate,
    this.completedDatesWithHabits = const {},
  }) : selectedDate = selectedDate ?? DateTime.now();

  HabitsState copyWith({
    List<HabitItem>? habits,
    bool? isLoading,
    String? errorMessage,
    DateTime? selectedDate,
    Set<String>? completedDatesWithHabits,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      completedDatesWithHabits: completedDatesWithHabits ?? this.completedDatesWithHabits,
    );
  }
}

class HabitsNotifier extends Notifier<HabitsState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  String _formatDateIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  HabitsState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchHabits();
      } else {
        state = HabitsState();
      }
    });

    Future.microtask(() => fetchHabits());

    return HabitsState(isLoading: true);
  }

  /// Set the selected date and reload habits/logs for that date
  void setSelectedDate(DateTime newDate) {
    fetchHabits(newDate);
  }

  /// Load user habits and completion logs for a given date from Supabase
  Future<void> fetchHabits([DateTime? targetDate]) async {
    final userId = _currentUserId;
    final selectedDate = targetDate ?? state.selectedDate;

    if (userId == null) {
      state = HabitsState(isLoading: false, habits: [], selectedDate: selectedDate);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, selectedDate: selectedDate);

    try {
      final habitsResponse = await _client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final selectedDateStr = _formatDateIso(selectedDate);

      // Determine week bounds (Sunday to Saturday) for completion dots in week-strip
      final daysFromSunday = selectedDate.weekday == DateTime.sunday ? 0 : selectedDate.weekday;
      final weekStart = selectedDate.subtract(Duration(days: daysFromSunday));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekStartStr = _formatDateIso(weekStart);
      final weekEndStr = _formatDateIso(weekEnd);

      Set<String> completedHabitIds = {};
      Set<String> completedDatesWithHabits = {};

      try {
        final logsResponse = await _client
            .from('habit_logs')
            .select()
            .eq('user_id', userId)
            .gte('log_date', weekStartStr)
            .lte('log_date', weekEndStr);

        for (final row in (logsResponse as List)) {
          final logDate = row['log_date'].toString();
          completedDatesWithHabits.add(logDate);
          if (logDate == selectedDateStr) {
            completedHabitIds.add(row['habit_id'].toString());
          }
        }
      } catch (e) {
        debugPrint('[HabitsNotifier] habit_logs lookup fallback: $e');
      }

      final List<HabitItem> items = (habitsResponse as List).map((row) {
        final habitId = row['id'].toString();
        final isCompletedToday = completedHabitIds.contains(habitId);
        return HabitItem.fromMap(row, isCompletedToday: isCompletedToday);
      }).toList();

      state = HabitsState(
        habits: items,
        isLoading: false,
        errorMessage: null,
        selectedDate: selectedDate,
        completedDatesWithHabits: completedDatesWithHabits,
      );
    } catch (e, st) {
      debugPrint('[HabitsNotifier] Error fetching habits: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load habits from Supabase',
      );
    }
  }

  /// Create a new habit row in Supabase
  Future<void> addHabit({
    required String title,
    required String timeOfDay,
    required String category,
    String? time,
    String? subtitle,
    int? reminderMinutesBefore,
    int? scheduledHour,
    int? scheduledMinute,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final tempItem = HabitItem(
      id: '',
      title: title,
      timeOfDay: timeOfDay,
      category: category.isEmpty ? 'Habits' : category,
      time: time,
      subtitle: subtitle,
      isCompleted: false,
      streakDays: 0,
      reminderMinutesBefore: reminderMinutesBefore,
      scheduledHour: scheduledHour,
      scheduledMinute: scheduledMinute,
    );

    try {
      final insertMap = tempItem.toMap(userId: userId);
      final response = await _client
          .from('habits')
          .insert(insertMap)
          .select()
          .single();

      final newItem = HabitItem.fromMap(response);

      state = state.copyWith(habits: [...state.habits, newItem]);

      if (reminderMinutesBefore != null && scheduledHour != null && scheduledMinute != null) {
        NotificationService.instance.scheduleHabitReminder(newItem);
      }
    } catch (e) {
      debugPrint('[HabitsNotifier] Error adding habit: $e');
      state = state.copyWith(errorMessage: 'Failed to add habit to Supabase');
    }
  }

  /// Swipe-to-complete a habit: inserts/deletes from habit_logs for selectedDate
  Future<void> toggleHabit(String id, [bool? forceCompleted]) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final habitIndex = state.habits.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentItem = state.habits[habitIndex];
    final newStatus = forceCompleted ?? !currentItem.isCompleted;
    final newStreak = newStatus
        ? currentItem.streakDays + 1
        : (currentItem.streakDays > 1 ? currentItem.streakDays - 1 : 0);

    final updatedItem = currentItem.copyWith(
      isCompleted: newStatus,
      streakDays: newStreak,
    );

    final updatedList = List<HabitItem>.from(state.habits);
    updatedList[habitIndex] = updatedItem;

    final selectedDateStr = _formatDateIso(state.selectedDate);
    final updatedCompletedDates = Set<String>.from(state.completedDatesWithHabits);
    if (newStatus) {
      updatedCompletedDates.add(selectedDateStr);
    } else {
      final hasOtherCompleted = updatedList.any((h) => h.isCompleted);
      if (!hasOtherCompleted) {
        updatedCompletedDates.remove(selectedDateStr);
      }
    }

    state = state.copyWith(
      habits: updatedList,
      completedDatesWithHabits: updatedCompletedDates,
    );

    try {
      if (newStatus) {
        try {
          await _client.from('habit_logs').upsert({
            'habit_id': id,
            'user_id': userId,
            'log_date': selectedDateStr,
          }, onConflict: 'habit_id, log_date');
        } catch (e) {
          debugPrint('[HabitsNotifier] habit_logs insert warning: $e');
        }
      } else {
        try {
          await _client
              .from('habit_logs')
              .delete()
              .eq('habit_id', id)
              .eq('log_date', selectedDateStr);
        } catch (e) {
          debugPrint('[HabitsNotifier] habit_logs delete warning: $e');
        }
      }

      await _client.from('habits').update({
        'is_completed': newStatus,
        'streak_days': newStreak,
      }).eq('id', id);

    } catch (e) {
      debugPrint('[HabitsNotifier] Error toggling habit: $e');
      final revertedList = List<HabitItem>.from(state.habits);
      revertedList[habitIndex] = currentItem;
      state = state.copyWith(habits: revertedList, errorMessage: 'Failed to update habit');
    }
  }

  /// Edit a habit in Supabase
  Future<void> editHabit(
    String id, {
    required String title,
    required String timeOfDay,
    required String category,
    String? time,
    String? subtitle,
    int? reminderMinutesBefore,
    int? scheduledHour,
    int? scheduledMinute,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final habitIndex = state.habits.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final currentItem = state.habits[habitIndex];
    final updatedItem = currentItem.copyWith(
      title: title,
      timeOfDay: timeOfDay,
      category: category,
      time: time,
      subtitle: subtitle,
      reminderMinutesBefore: reminderMinutesBefore,
      scheduledHour: scheduledHour,
      scheduledMinute: scheduledMinute,
    );

    final updatedList = List<HabitItem>.from(state.habits);
    updatedList[habitIndex] = updatedItem;
    state = state.copyWith(habits: updatedList);

    try {
      await _client.from('habits').update({
        'title': title,
        'time_of_day': timeOfDay,
        'category': category,
        'scheduled_time': time,
        'subtitle': subtitle,
        'reminder_minutes_before': reminderMinutesBefore,
        'scheduled_hour': scheduledHour,
        'scheduled_minute': scheduledMinute,
      }).eq('id', id);

      if (reminderMinutesBefore != null && scheduledHour != null && scheduledMinute != null) {
        NotificationService.instance.scheduleHabitReminder(updatedItem);
      } else {
        NotificationService.instance.cancelHabitReminder(id);
      }
    } catch (e) {
      debugPrint('[HabitsNotifier] Error editing habit: $e');
      state = state.copyWith(errorMessage: 'Failed to edit habit');
    }
  }

  /// Delete a habit from Supabase
  Future<void> deleteHabit(String id) async {
    final habitIndex = state.habits.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final removedItem = state.habits[habitIndex];
    state = state.copyWith(
      habits: state.habits.where((h) => h.id != id).toList(),
    );

    try {
      NotificationService.instance.cancelHabitReminder(id);
      await _client.from('habits').delete().eq('id', id);
    } catch (e) {
      debugPrint('[HabitsNotifier] Error deleting habit: $e');
      state = state.copyWith(
        habits: [...state.habits, removedItem],
        errorMessage: 'Failed to delete habit',
      );
    }
  }
}

final habitsProvider = NotifierProvider<HabitsNotifier, HabitsState>(() {
  return HabitsNotifier();
});

/// Convenience provider returning List<HabitItem> for widgets that only need the list
final habitsListProvider = Provider<List<HabitItem>>((ref) {
  return ref.watch(habitsProvider).habits;
});
