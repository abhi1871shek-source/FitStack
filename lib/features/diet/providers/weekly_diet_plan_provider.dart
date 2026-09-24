import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/food_database_data.dart';
import '../models/food_item.dart';
import '../models/weekly_diet_plan.dart';
import '../providers/diet_preference_provider.dart';

class WeeklyDietPlanState {
  final List<PlannedDay> days;
  final bool isLoading;
  final String? errorMessage;

  const WeeklyDietPlanState({
    this.days = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WeeklyDietPlanState copyWith({
    List<PlannedDay>? days,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WeeklyDietPlanState(
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WeeklyDietPlanNotifier extends Notifier<WeeklyDietPlanState> {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  WeeklyDietPlanState build() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchWeeklyPlan();
      } else {
        state = const WeeklyDietPlanState();
      }
    });

    Future.microtask(() => fetchWeeklyPlan());

    return const WeeklyDietPlanState(isLoading: true);
  }

  Future<void> fetchWeeklyPlan() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = const WeeklyDietPlanState(isLoading: false, days: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _client
          .from('weekly_diet_plans')
          .select()
          .eq('user_id', userId)
          .order('day_index', ascending: true);

      final List rows = response as List;
      final now = DateTime.now();
      final todayIndex = now.weekday - 1; // 0=Mon, 6=Sun

      if (rows.isEmpty) {
        // Seed weekly plan based on diet preferences
        final prefs = ref.read(dietPreferenceProvider);
        final initialDays = _generateWeeklyPlan(prefs);

        final insertList = <Map<String, dynamic>>[];
        for (int dayIdx = 0; dayIdx < initialDays.length; dayIdx++) {
          final day = initialDays[dayIdx];
          for (final meal in day.meals) {
            insertList.add(meal.toMap(
              userId: userId,
              dayName: day.dayName,
              shortName: day.shortName,
              dayIndex: dayIdx,
              dateNum: day.dateNum,
            ));
          }
        }

        if (insertList.isNotEmpty) {
          await _client.from('weekly_diet_plans').insert(insertList);
        }

        state = WeeklyDietPlanState(days: initialDays, isLoading: false);
      } else {
        // Group rows by day_index
        final Map<int, List<PlannedMeal>> groupedMeals = {};
        final Map<int, Map<String, dynamic>> dayMeta = {};

        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final dayIdx = (map['day_index'] as int?) ?? 0;
          groupedMeals.putIfAbsent(dayIdx, () => []).add(PlannedMeal.fromMap(map));
          dayMeta[dayIdx] = map;
        }

        final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        final List<PlannedDay> days = List.generate(7, (i) {
          final meta = dayMeta[i];
          final dayName = meta?['day_name'] as String? ?? dayNames[i];
          final shortName = meta?['short_name'] as String? ?? shortNames[i];
          final dateNum = meta?['date_num'] as int? ?? (now.day + (i - todayIndex));
          final meals = groupedMeals[i] ?? [];
          final isToday = i == todayIndex;

          return PlannedDay(
            dayName: dayName,
            shortName: shortName,
            dateNum: dateNum,
            meals: meals,
            isToday: isToday,
          );
        });

        state = WeeklyDietPlanState(days: days, isLoading: false);
      }
    } catch (e, st) {
      debugPrint('[WeeklyDietPlanNotifier] Error fetching plan: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load weekly diet plan from Supabase',
      );
    }
  }

  List<PlannedDay> _generateWeeklyPlan(dynamic prefs) {
    final target = prefs.calorieTarget ?? 1800;
    final mealsPerDay = prefs.mealsPerDay as int;
    final cuisines = prefs.selectedCuisines as List<String>;
    final dietType = prefs.dietaryType as String;

    final pool = _filteredPool(cuisines, dietType);
    final sections = _sectionBudgets(mealsPerDay, target);

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (dayIndex) {
      final dayDate = monday.add(Duration(days: dayIndex));
      final isToday = dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;

      final meals = <PlannedMeal>[];
      final dayOffset = dayIndex * 3;
      final usedIds = <String>{};

      for (int si = 0; si < sections.length; si++) {
        final section = sections[si];
        final budget = section['budget'] as double;
        final label = section['label'] as String;

        final food = _pickNearest(pool, budget, (dayOffset + si) % pool.length, usedIds);
        usedIds.add(food.id);
        meals.add(PlannedMeal(
          foodId: food.id,
          name: food.name,
          cuisine: food.cuisine,
          mealSection: label,
          calories: food.calories,
          proteinGrams: food.proteinGrams,
          carbsGrams: food.carbsGrams,
          fatGrams: food.fatGrams,
          servingDescription: food.baseServing,
          imageAsset: food.imageAsset.isNotEmpty
              ? food.imageAsset
              : 'assets/images/food/${food.id}.jpg',
        ));
      }

      return PlannedDay(
        dayName: dayNames[dayIndex],
        shortName: shortNames[dayIndex],
        dateNum: dayDate.day,
        meals: meals,
        isToday: isToday,
      );
    });
  }

  List<FoodItem> _filteredPool(List<String> cuisines, String dietType) {
    final allowed = <String>{};
    switch (dietType.toLowerCase()) {
      case 'vegan':
        allowed.add('vegan');
      case 'vegetarian':
        allowed.addAll(['vegan', 'vegetarian']);
      case 'eggetarian':
        allowed.addAll(['vegan', 'vegetarian', 'eggetarian']);
      default:
        allowed.addAll(['vegan', 'vegetarian', 'eggetarian', 'non-vegetarian']);
    }

    final pool = FoodDatabaseData.masterFoods
        .where((f) => cuisines.contains(f.cuisine) && allowed.contains(f.dietaryType))
        .toList();

    if (pool.length < 5) {
      return FoodDatabaseData.masterFoods
          .where((f) => allowed.contains(f.dietaryType))
          .toList();
    }
    return pool;
  }

  List<Map<String, dynamic>> _sectionBudgets(int mealsPerDay, int target) {
    switch (mealsPerDay) {
      case 3:
        return [
          {'label': 'Breakfast', 'budget': target * 0.30},
          {'label': 'Lunch', 'budget': target * 0.40},
          {'label': 'Dinner', 'budget': target * 0.30},
        ];
      case 5:
        return [
          {'label': 'Breakfast', 'budget': target * 0.20},
          {'label': 'Lunch', 'budget': target * 0.30},
          {'label': 'Snack', 'budget': target * 0.12},
          {'label': 'Snack 2', 'budget': target * 0.10},
          {'label': 'Dinner', 'budget': target * 0.28},
        ];
      default:
        return [
          {'label': 'Breakfast', 'budget': target * 0.25},
          {'label': 'Lunch', 'budget': target * 0.35},
          {'label': 'Snack', 'budget': target * 0.15},
          {'label': 'Dinner', 'budget': target * 0.25},
        ];
    }
  }

  FoodItem _pickNearest(List<FoodItem> pool, double budget, int startIndex, [Set<String>? excludeIds]) {
    FoodItem? best;
    double bestDiff = double.infinity;

    for (int i = 0; i < pool.length; i++) {
      final candidate = pool[(startIndex + i) % pool.length];
      if (excludeIds != null && excludeIds.contains(candidate.id)) continue;
      final diff = (candidate.calories - budget).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = candidate;
      }
    }

    return best ?? pool[startIndex % pool.length];
  }

  Future<void> regenerate() async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      await _client.from('weekly_diet_plans').delete().eq('user_id', userId);
      await fetchWeeklyPlan();
    } catch (e) {
      debugPrint('[WeeklyDietPlanNotifier] Error regenerating plan: $e');
    }
  }

  Future<void> swapMeal({
    required int dayIndex,
    required int mealIndex,
    required String newFoodId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final food = FoodDatabaseData.masterFoods
        .firstWhere((f) => f.id == newFoodId, orElse: () => FoodDatabaseData.masterFoods.first);

    final updatedDays = List<PlannedDay>.from(state.days);
    final day = updatedDays[dayIndex];
    final updatedMeals = List<PlannedMeal>.from(day.meals);

    updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(
      foodId: food.id,
      name: food.name,
      cuisine: food.cuisine,
      calories: food.calories,
      proteinGrams: food.proteinGrams,
      carbsGrams: food.carbsGrams,
      fatGrams: food.fatGrams,
    );

    updatedDays[dayIndex] = day.copyWith(meals: updatedMeals);
    state = state.copyWith(days: updatedDays);

    try {
      await _client
          .from('weekly_diet_plans')
          .update({
            'food_id': food.id,
            'meal_name': food.name,
            'cuisine': food.cuisine,
            'calories': food.calories,
            'protein_grams': food.proteinGrams,
            'carbs_grams': food.carbsGrams,
            'fat_grams': food.fatGrams,
          })
          .eq('user_id', userId)
          .eq('day_index', dayIndex)
          .eq('meal_section', updatedMeals[mealIndex].mealSection);
    } catch (e) {
      debugPrint('[WeeklyDietPlanNotifier] Error swapping meal: $e');
    }
  }
}

final weeklyDietPlanProvider = NotifierProvider<WeeklyDietPlanNotifier, WeeklyDietPlanState>(() {
  return WeeklyDietPlanNotifier();
});

/// Convenience provider returning List<PlannedDay>
final weeklyDietPlanListProvider = Provider<List<PlannedDay>>((ref) {
  return ref.watch(weeklyDietPlanProvider).days;
});
