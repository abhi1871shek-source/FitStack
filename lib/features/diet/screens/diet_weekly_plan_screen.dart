import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/food_database_data.dart';
import '../models/weekly_diet_plan.dart';
import '../providers/diet_preference_provider.dart';
import '../providers/weekly_diet_plan_provider.dart';

class DietWeeklyPlanScreen extends ConsumerStatefulWidget {
  const DietWeeklyPlanScreen({super.key});

  @override
  ConsumerState<DietWeeklyPlanScreen> createState() =>
      _DietWeeklyPlanScreenState();
}

class _DietWeeklyPlanScreenState extends ConsumerState<DietWeeklyPlanScreen> {
  late int _selectedDayIndex;
  final _dayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default to today
    final now = DateTime.now();
    _selectedDayIndex = now.weekday - 1; // 0=Mon … 6=Sun
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weeklyPlan = ref.watch(weeklyDietPlanListProvider);
    final prefs = ref.watch(dietPreferenceProvider);
    final target = prefs.calorieTarget ?? 1800;

    // Safety clamp
    if (_selectedDayIndex >= weeklyPlan.length) _selectedDayIndex = 0;
    final selectedDay = weeklyPlan[_selectedDayIndex];
    final dailyTotal = selectedDay.totalCalories;
    final adherence = target > 0 ? (dailyTotal / target).clamp(0.0, 1.0) : 0.0;
    final adherencePct = (adherence * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Weekly Diet Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              '$target kcal/day target',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 22, color: AppColors.textMuted),
            tooltip: 'Regenerate Plan',
            onPressed: () {
              ref.read(weeklyDietPlanProvider.notifier).regenerate();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Day selector row ──
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubdued)),
            ),
            child: SingleChildScrollView(
              controller: _dayScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: weeklyPlan.asMap().entries.map((entry) {
                  final i = entry.key;
                  final day = entry.value;
                  final isSelected = i == _selectedDayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 54,
                      height: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (day.isToday ? AppColors.primary.withOpacity(0.4) : AppColors.borderSubdued),
                          width: day.isToday && !isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.shortName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withOpacity(0.85) : AppColors.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.dateNum}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Meal list for selected day ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Day header
                Row(
                  children: [
                    Text(
                      selectedDay.dayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (selectedDay.isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Meal cards
                ...selectedDay.meals.asMap().entries.map((entry) {
                  final mealIdx = entry.key;
                  final meal = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildMealCard(meal, _selectedDayIndex, mealIdx),
                  );
                }),

                const SizedBox(height: 12),

                // ── Daily summary card ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubdued),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$adherencePct% on track',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: adherencePct >= 95 && adherencePct <= 105
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${dailyTotal.round()}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                TextSpan(
                                  text: ' / $target kcal',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: adherence,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceSubdued,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            adherencePct >= 95 && adherencePct <= 105
                                ? AppColors.primary
                                : (adherencePct > 105 ? Colors.orange.shade600 : AppColors.metricGreen),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 0, color: AppColors.borderSubdued),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _macroStat('Protein', '${selectedDay.totalProtein.round()}g'),
                          _macroStat('Carbs', '${selectedDay.totalCarbs.round()}g'),
                          _macroStat('Fat', '${selectedDay.totalFat.round()}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(PlannedMeal meal, int dayIdx, int mealIdx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubdued),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meal.mealSection.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () => _showSwapDialog(dayIdx, mealIdx, meal),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const Divider(height: 10, color: AppColors.borderSubdued),
          const SizedBox(height: 2),

          // Food name + calories
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal.servingDescription,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories.round()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text('kcal', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),

          // Macro badges
          const SizedBox(height: 10),
          const Divider(height: 0, color: AppColors.borderSubdued),
          const SizedBox(height: 8),
          Row(
            children: [
              _macroBadge('P: ${meal.proteinGrams.round()}g'),
              const SizedBox(width: 6),
              _macroBadge('C: ${meal.carbsGrams.round()}g'),
              const SizedBox(width: 6),
              _macroBadge('F: ${meal.fatGrams.round()}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubdued,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _macroStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  void _showSwapDialog(int dayIdx, int mealIdx, PlannedMeal currentMeal) {
    final prefs = ref.read(dietPreferenceProvider);
    final cuisines = prefs.selectedCuisines;
    final dietType = prefs.dietaryType;

    // Build filtered options
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

    final options = FoodDatabaseData.masterFoods
        .where((f) => cuisines.contains(f.cuisine) && allowed.contains(f.dietaryType))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubdued,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Swap Meal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Current: ${currentMeal.name}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final f = options[i];
                  final isCurrent = f.id == currentMeal.foodId;
                  return ListTile(
                    title: Text(
                      f.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${f.calories.round()} kcal  •  ${f.baseServing}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18)
                        : null,
                    onTap: () {
                      ref.read(weeklyDietPlanProvider.notifier).swapMeal(
                            dayIndex: dayIdx,
                            mealIndex: mealIdx,
                            newFoodId: f.id,
                          );
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
