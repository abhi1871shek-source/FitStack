import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/food_database_data.dart';
import '../models/food_item.dart';
import '../models/weekly_diet_plan.dart';

class FoodLogState {
  final List<LoggedFoodItem> logs;
  final bool isLoading;
  final String? errorMessage;

  const FoodLogState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FoodLogState copyWith({
    List<LoggedFoodItem>? logs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FoodLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class FoodLogNotifier extends Notifier<FoodLogState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  FoodLogState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchTodayLogs();
      } else {
        state = const FoodLogState();
      }
    });

    Future.microtask(() => fetchTodayLogs());

    return const FoodLogState(isLoading: true);
  }

  /// Ensure master food items exist in Supabase food_items table
  Future<void> _ensureMasterFoodsExist() async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      final masterMaps = FoodDatabaseData.masterFoods.map((f) {
        final map = f.toMap(userId: null);
        return map;
      }).toList();
      await _client.from('food_items').upsert(masterMaps, onConflict: 'id');
    } catch (e) {
      debugPrint('[FoodLogNotifier] Master foods upsert note: $e');
    }
  }

  /// Load today's logged meals from Supabase
  Future<void> fetchTodayLogs() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const FoodLogState(isLoading: false, logs: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    try {
      await _ensureMasterFoodsExist();

      final response = await _client
          .from('food_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', todayStr)
          .order('created_at', ascending: true);

      final List rows = response as List;

      if (rows.isEmpty) {
        state = const FoodLogState(logs: [], isLoading: false);
      } else {
        final List<LoggedFoodItem> items = rows.map((row) => LoggedFoodItem.fromMap(row)).toList();
        state = FoodLogState(logs: items, isLoading: false);
      }
    } catch (e, st) {
      debugPrint('[FoodLogNotifier] Error fetching food logs: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load food logs from Supabase',
      );
    }
  }

  /// Add multiple selected food items to today's log in Supabase
  Future<void> addLoggedFoods(
    List<FoodItem> foods, {
    String mealSection = 'Lunch',
    double? customQuantityGrams,
    String? loggedTime,
  }) async {
    final userId = _currentUserId;
    if (userId == null || foods.isEmpty) return;

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final nowTime = loggedTime ?? _formatCurrentTime();

    await _ensureMasterFoodsExist();

    final newItems = foods.map((food) {
      final qty = customQuantityGrams ?? food.baseServingGrams;
      return LoggedFoodItem.fromFoodItem(
        id: '',
        food: food,
        mealSection: mealSection,
        quantityGrams: qty,
        unit: 'g',
        loggedTime: nowTime,
      );
    }).toList();

    final insertList = newItems.map((item) => item.toMap(userId: userId, logDate: todayStr)).toList();

    try {
      final insertedResponse = await _client.from('food_logs').insert(insertList).select();

      final List<LoggedFoodItem> insertedLogs = (insertedResponse as List)
          .map((row) => LoggedFoodItem.fromMap(row))
          .toList();

      state = state.copyWith(logs: [...state.logs, ...insertedLogs]);
    } catch (e) {
      debugPrint('[FoodLogNotifier] Error adding food log: $e');
      state = state.copyWith(errorMessage: 'Failed to add food log to database');
    }
  }

  /// Add a single logged food item
  Future<void> addLoggedFood({
    required FoodItem food,
    required String mealSection,
    required double quantityGrams,
    String unit = 'g',
    String? loggedTime,
  }) async {
    await addLoggedFoods(
      [food],
      mealSection: mealSection,
      customQuantityGrams: quantityGrams,
      loggedTime: loggedTime,
    );
  }

  /// Edit quantity or meal section of an existing logged food item
  Future<void> editLoggedFood(
    String id, {
    required double quantityGrams,
    required String mealSection,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index = state.logs.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final currentItem = state.logs[index];

    final baseFood = FoodDatabaseData.masterFoods.firstWhere(
      (f) => f.id == currentItem.foodId,
      orElse: () => FoodItem(
        id: currentItem.foodId,
        name: currentItem.name,
        cuisine: currentItem.cuisine,
        baseServing: '${currentItem.quantityGrams}g',
        baseServingGrams: currentItem.quantityGrams > 0 ? currentItem.quantityGrams : 100.0,
        calories: currentItem.calories,
        proteinGrams: currentItem.proteinGrams,
        carbsGrams: currentItem.carbsGrams,
        fatGrams: currentItem.fatGrams,
        fiberGrams: currentItem.fiberGrams,
        category: 'Meals',
      ),
    );

    final updatedItem = LoggedFoodItem.fromFoodItem(
      id: id,
      food: baseFood,
      mealSection: mealSection,
      quantityGrams: quantityGrams,
      unit: currentItem.unit,
      loggedTime: currentItem.loggedTime,
    );

    final updatedList = List<LoggedFoodItem>.from(state.logs);
    updatedList[index] = updatedItem;
    state = state.copyWith(logs: updatedList);

    try {
      await _client.from('food_logs').update({
        'quantity_grams': updatedItem.quantityGrams,
        'meal_section': updatedItem.mealSection,
        'calories': updatedItem.calories,
        'protein_grams': updatedItem.proteinGrams,
        'carbs_grams': updatedItem.carbsGrams,
        'fat_grams': updatedItem.fatGrams,
        'fiber_grams': updatedItem.fiberGrams,
      }).eq('id', id);
    } catch (e) {
      debugPrint('[FoodLogNotifier] Error editing food log: $e');
      final revertedList = List<LoggedFoodItem>.from(state.logs);
      revertedList[index] = currentItem;
      state = state.copyWith(logs: revertedList, errorMessage: 'Failed to edit food log');
    }
  }

  /// Delete a logged food item from Supabase
  Future<void> deleteLoggedFood(String id) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final index = state.logs.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final removedItem = state.logs[index];
    state = state.copyWith(
      logs: state.logs.where((item) => item.id != id).toList(),
    );

    try {
      await _client.from('food_logs').delete().eq('id', id);
    } catch (e) {
      debugPrint('[FoodLogNotifier] Error deleting food log: $e');
      state = state.copyWith(
        logs: [...state.logs, removedItem],
        errorMessage: 'Failed to delete food log',
      );
    }
  }

  /// Import planned meals from user's personalized weekly diet plan into today's log
  Future<void> importPlannedMeals(List<PlannedMeal> meals) async {
    final userId = _currentUserId;
    if (userId == null || meals.isEmpty) return;

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final nowTime = _formatCurrentTime();

    await _ensureMasterFoodsExist();

    final insertList = meals.map((m) {
      return {
        'user_id': userId,
        'log_date': todayStr,
        'food_id': m.foodId.isNotEmpty ? m.foodId : 'f_custom_${DateTime.now().millisecondsSinceEpoch}',
        'name': m.name,
        'cuisine': m.cuisine,
        'meal_section': m.mealSection,
        'quantity_grams': 100.0,
        'unit': 'g',
        'calories': m.calories,
        'protein_grams': m.proteinGrams,
        'carbs_grams': m.carbsGrams,
        'fat_grams': m.fatGrams,
        'fiber_grams': 5.0,
        'logged_time': nowTime,
      };
    }).toList();

    try {
      final insertedResponse = await _client.from('food_logs').insert(insertList).select();

      final List<LoggedFoodItem> insertedLogs = (insertedResponse as List)
          .map((row) => LoggedFoodItem.fromMap(row))
          .toList();

      state = state.copyWith(logs: [...state.logs, ...insertedLogs]);
    } catch (e) {
      debugPrint('[FoodLogNotifier] Error importing planned meals: $e');
      state = state.copyWith(errorMessage: 'Failed to import planned meals to database');
    }
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}

final foodLogProvider = NotifierProvider<FoodLogNotifier, FoodLogState>(() {
  return FoodLogNotifier();
});

/// Convenience provider returning List<LoggedFoodItem>
final foodLogListProvider = Provider<List<LoggedFoodItem>>((ref) {
  return ref.watch(foodLogProvider).logs;
});
