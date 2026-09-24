import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';

class WorkoutState {
  final List<WorkoutLogItem> logs;
  final bool isLoading;
  final String? errorMessage;

  const WorkoutState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkoutState copyWith({
    List<WorkoutLogItem>? logs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkoutState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkoutNotifier extends Notifier<WorkoutState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  WorkoutState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchTodayWorkout();
      } else {
        state = const WorkoutState();
      }
    });

    Future.microtask(() => fetchTodayWorkout());

    return const WorkoutState(isLoading: true);
  }

  /// Ensure master exercise library exists in Supabase exercises table
  Future<void> _ensureMasterExercisesExist() async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      final masterMaps = ExerciseLibrary.masterExercises.map((e) {
        final map = e.toMap();
        map['user_id'] = userId;
        return map;
      }).toList();
      await _client.from('exercises').upsert(masterMaps, onConflict: 'id');
    } catch (e) {
      debugPrint('[WorkoutNotifier] Master exercises upsert note: $e');
    }
  }

  /// Load today's logged exercises from Supabase (or seed them if missing)
  Future<void> fetchTodayWorkout() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const WorkoutState(isLoading: false, logs: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    try {
      await _ensureMasterExercisesExist();

      final response = await _client
          .from('workout_logs')
          .select()
          .eq('user_id', userId)
          .eq('workout_date', todayStr)
          .order('created_at', ascending: true);

      final List rows = response as List;

      if (rows.isEmpty) {
        final defaultSeedItems = [
          const WorkoutLogItem(
            id: '',
            exerciseId: 'ex_1',
            name: 'Barbell Bench Press',
            muscleGroup: 'Chest',
            sets: 4,
            reps: 10,
            weightKg: 70.0,
            isCompleted: false,
            imageUrl: 'assets/images/exercises/ex_1.jpg',
          ),
          const WorkoutLogItem(
            id: '',
            exerciseId: 'ex_2',
            name: 'Incline Dumbbell Press',
            muscleGroup: 'Chest',
            sets: 3,
            reps: 12,
            weightKg: 24.0,
            isCompleted: false,
            imageUrl: 'assets/images/exercises/ex_2.jpg',
          ),
          const WorkoutLogItem(
            id: '',
            exerciseId: 'ex_6',
            name: 'Lat Pulldown',
            muscleGroup: 'Back',
            sets: 4,
            reps: 12,
            weightKg: 55.0,
            isCompleted: false,
            imageUrl: 'assets/images/exercises/ex_6.jpg',
          ),
          const WorkoutLogItem(
            id: '',
            exerciseId: 'ex_13',
            name: 'Overhead Dumbbell Press',
            muscleGroup: 'Shoulders',
            sets: 3,
            reps: 10,
            weightKg: 18.0,
            isCompleted: true,
            imageUrl: 'assets/images/exercises/ex_13.jpg',
          ),
        ];

        final insertList = defaultSeedItems
            .map((item) => item.toMap(userId: userId, workoutDate: todayStr))
            .toList();

        final insertedResponse = await _client
            .from('workout_logs')
            .insert(insertList)
            .select();

        final List<WorkoutLogItem> seededList = (insertedResponse as List)
            .map((row) => WorkoutLogItem.fromMap(row))
            .toList();

        state = WorkoutState(logs: seededList, isLoading: false);
      } else {
        final List<WorkoutLogItem> items =
            rows.map((row) => WorkoutLogItem.fromMap(row)).toList();
        state = WorkoutState(logs: items, isLoading: false);
      }
    } catch (e, st) {
      debugPrint('[WorkoutNotifier] Error fetching today workout: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load today workout from Supabase',
      );
    }
  }

  /// Update set/exercise completion on real workout_logs row
  Future<void> toggleComplete(String id, [bool? forceCompleted]) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index = state.logs.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final currentItem = state.logs[index];
    final newStatus = forceCompleted ?? !currentItem.isCompleted;
    final updatedItem = currentItem.copyWith(isCompleted: newStatus);

    final updatedList = List<WorkoutLogItem>.from(state.logs);
    updatedList[index] = updatedItem;
    state = state.copyWith(logs: updatedList);

    try {
      await _client
          .from('workout_logs')
          .update({'is_completed': newStatus})
          .eq('id', id);
    } catch (e) {
      debugPrint('[WorkoutNotifier] Error toggling complete: $e');
      final revertedList = List<WorkoutLogItem>.from(state.logs);
      revertedList[index] = currentItem;
      state = state.copyWith(logs: revertedList, errorMessage: 'Failed to update exercise completion');
    }
  }

  /// Add new exercises from library into workout_logs in Supabase
  Future<void> addExercises(List<Exercise> selectedExercises) async {
    final userId = _currentUserId;
    if (userId == null || selectedExercises.isEmpty) return;

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    await _ensureMasterExercisesExist();

    final insertList = selectedExercises.map((ex) {
      return {
        'user_id': userId,
        'exercise_id': ex.id,
        'name': ex.name,
        'muscle_group': ex.muscleGroup,
        'sets': ex.defaultSets,
        'reps': ex.defaultReps,
        'weight_kg': ex.defaultWeightKg,
        'is_completed': false,
        'image_url': ex.imageUrl,
        'workout_date': todayStr,
      };
    }).toList();

    try {
      final insertedResponse = await _client
          .from('workout_logs')
          .insert(insertList)
          .select();

      final List<WorkoutLogItem> newItems = (insertedResponse as List)
          .map((row) => WorkoutLogItem.fromMap(row))
          .toList();

      state = state.copyWith(logs: [...state.logs, ...newItems]);
    } catch (e) {
      debugPrint('[WorkoutNotifier] Error adding exercises: $e');
      state = state.copyWith(errorMessage: 'Failed to add exercises to database');
    }
  }

  /// Edit sets, reps, and weight on workout_logs row in Supabase
  Future<void> editExercise(
    String id, {
    required int sets,
    required int reps,
    required double weightKg,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index = state.logs.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final currentItem = state.logs[index];
    final updatedItem = currentItem.copyWith(
      sets: sets,
      reps: reps,
      weightKg: weightKg,
    );

    final updatedList = List<WorkoutLogItem>.from(state.logs);
    updatedList[index] = updatedItem;
    state = state.copyWith(logs: updatedList);

    try {
      await _client.from('workout_logs').update({
        'sets': sets,
        'reps': reps,
        'weight_kg': weightKg,
      }).eq('id', id);
    } catch (e) {
      debugPrint('[WorkoutNotifier] Error editing exercise: $e');
      final revertedList = List<WorkoutLogItem>.from(state.logs);
      revertedList[index] = currentItem;
      state = state.copyWith(logs: revertedList, errorMessage: 'Failed to edit exercise');
    }
  }

  /// Delete exercise row from workout_logs in Supabase
  Future<void> deleteExercise(String id) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index = state.logs.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removedItem = state.logs[index];
    state = state.copyWith(
      logs: state.logs.where((item) => item.id != id).toList(),
    );

    try {
      await _client.from('workout_logs').delete().eq('id', id);
    } catch (e) {
      debugPrint('[WorkoutNotifier] Error deleting exercise: $e');
      state = state.copyWith(
        logs: [...state.logs, removedItem],
        errorMessage: 'Failed to delete exercise',
      );
    }
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(() {
  return WorkoutNotifier();
});

/// Convenience provider returning List<WorkoutLogItem>
final workoutListProvider = Provider<List<WorkoutLogItem>>((ref) {
  return ref.watch(workoutProvider).logs;
});
