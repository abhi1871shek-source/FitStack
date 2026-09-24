import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_streak_counter.dart';
import '../../../core/widgets/emoji_progress_bar.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../models/food_item.dart';
import '../providers/food_log_provider.dart';
import 'diet_preference_screen.dart';
import 'food_database_screen.dart';
import 'quick_add_food_sheet.dart';
import '../providers/diet_preference_provider.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final double _dailyProteinGoal = 150.0;
  final double _dailyCarbsGoal = 220.0;
  final double _dailyFatGoal = 65.0;
  final double _dailyFiberGoal = 30.0;

  void _openQuickAddSheet(BuildContext context, {String? mealSection}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddFoodSheet(initialMealSection: mealSection),
    );
  }

  void _openFoodDatabaseScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodDatabaseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodLogState = ref.watch(foodLogProvider);
    final loggedFoods = foodLogState.logs;
    final notifier = ref.read(foodLogProvider.notifier);

    final dietPrefs = ref.watch(dietPreferenceProvider);
    final double dailyCalorieGoal = (dietPrefs.calorieTarget ?? 2000).toDouble();

    final bgColor = AppColors.ofBackground(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);

    if (foodLogState.isLoading && loggedFoods.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Calculate live daily totals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;

    for (final item in loggedFoods) {
      totalCalories += item.calories;
      totalProtein += item.proteinGrams;
      totalCarbs += item.carbsGrams;
      totalFat += item.fatGrams;
      totalFiber += item.fiberGrams;
    }

    final calorieProgress = (totalCalories / dailyCalorieGoal).clamp(0.0, 1.0);

    // Group logged items by fixed meal section sequence: Breakfast -> Lunch -> Snacks -> Dinner
    final mealSections = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];
    final Map<String, List<LoggedFoodItem>> groupedItems = {
      'Breakfast': [],
      'Lunch': [],
      'Snacks': [],
      'Dinner': [],
    };

    for (final item in loggedFoods) {
      if (groupedItems.containsKey(item.mealSection)) {
        groupedItems[item.mealSection]!.add(item);
      } else {
        groupedItems['Snacks']!.add(item);
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & Daily Calorie + Macro Telemetry Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Food & Nutrition',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Today • ${totalCalories.round()} of ${dailyCalorieGoal.round()} kcal eaten',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DietPreferenceScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.restaurant_menu_outlined, size: 20, color: AppColors.primary),
                            tooltip: 'Diet Preferences & Weekly Plan',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accentSubtle,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _openFoodDatabaseScreen(context),
                            icon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                            tooltip: 'Browse Food Database',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.ofCardSurface(context),
                              side: BorderSide(color: AppColors.ofBorderSubdued(context)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _openQuickAddSheet(context),
                            icon: const Icon(Icons.add, size: 22, color: AppColors.primary),
                            tooltip: 'Quick Add Food',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accentSubtle,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calorie Progress Bar (🔥)
                  EmojiProgressBar(
                    progress: calorieProgress,
                    emoji: '🔥',
                    height: 8,
                    barColor: AppColors.primary,
                  ),
                  const SizedBox(height: 14),

                  // Compact Macro Tracker Cards (Protein / Carbs / Fat / Fiber)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroCard(
                          context,
                          'Protein',
                          totalProtein,
                          _dailyProteinGoal,
                          'g',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMacroCard(
                          context,
                          'Carbs',
                          totalCarbs,
                          _dailyCarbsGoal,
                          'g',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMacroCard(
                          context,
                          'Fat',
                          totalFat,
                          _dailyFatGoal,
                          'g',
                          Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMacroCard(
                          context,
                          'Fiber',
                          totalFiber,
                          _dailyFiberGoal,
                          'g',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Meal Log List Grouped by Fixed Section Sequence
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  ...mealSections.map((sectionName) {
                    final items = groupedItems[sectionName] ?? [];
                    final sectionCalories = items.fold(0.0, (sum, i) => sum + i.calories);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _getMealSectionIcon(sectionName),
                                const SizedBox(width: 6),
                                Text(
                                  sectionName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${items.length})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${sectionCalories.round()} kcal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _openQuickAddSheet(context, mealSection: sectionName),
                                  child: const Text(
                                    '+ Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Section Items or Empty Placeholder
                        if (items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.ofCardSurface(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.ofBorderSubdued(context).withOpacity(0.6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'No food logged for $sectionName',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                InkWell(
                                  onTap: () => _openQuickAddSheet(context, mealSection: sectionName),
                                  child: const Text(
                                    '+ Add Item',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...items.map((loggedItem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildLoggedFoodCard(context, loggedItem, notifier),
                            );
                          }),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),

                  const SizedBox(height: 80), // Bottom padding above FAB
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button (+)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _openQuickAddSheet(context),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Quick Add Food', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacroCard(BuildContext context, String label, double current, double goal, String unit, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ofCardSurface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ofBorderSubdued(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ofTextMuted(context), letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          AnimatedStreakCounter(
            count: current.round(),
            suffix: ' / ${goal.round()}$unit',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.ofSurfaceSubdued(context),
              color: color,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getMealSectionIcon(String sectionName) {
    switch (sectionName.toLowerCase()) {
      case 'breakfast':
        return const Icon(Icons.free_breakfast_outlined, size: 15, color: AppColors.primary);
      case 'lunch':
        return const Icon(Icons.lunch_dining_outlined, size: 15, color: AppColors.primary);
      case 'snacks':
        return const Icon(Icons.bakery_dining_outlined, size: 15, color: AppColors.primary);
      case 'dinner':
        return const Icon(Icons.dinner_dining_outlined, size: 15, color: AppColors.primary);
      default:
        return const Icon(Icons.restaurant, size: 15, color: AppColors.primary);
    }
  }

  Widget _buildLoggedFoodCard(BuildContext context, LoggedFoodItem item, FoodLogNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ofCardSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ofBorderSubdued(context)),
      ),
      child: Row(
        children: [
          // Food Dish Image Thumbnail
          InkWell(
            onTap: () {
              final imgPath = item.imageAsset.isNotEmpty ? item.imageAsset : 'assets/images/food/${item.foodId}.jpg';
              showImagePreviewDialog(context, imgPath, item.name);
            },
            onDoubleTap: () {
              final imgPath = item.imageAsset.isNotEmpty ? item.imageAsset : 'assets/images/food/${item.foodId}.jpg';
              showImagePreviewDialog(context, imgPath, item.name);
            },
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imageAsset.isNotEmpty ? item.imageAsset : 'assets/images/food/${item.foodId}.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40,
                  height: 40,
                  color: AppColors.ofSurfaceSubdued(context),
                  child: Icon(Icons.restaurant, size: 18, color: AppColors.ofTextMuted(context)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Food Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ofTextPrimary(context)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${item.quantityGrams.toStringAsFixed(0)}${item.unit} • ${item.calories.round()} kcal',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'P: ${item.proteinGrams.toStringAsFixed(1)}g • C: ${item.carbsGrams.toStringAsFixed(1)}g • F: ${item.fatGrams.toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 10, color: AppColors.ofTextMuted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delete Action
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => notifier.deleteLoggedFood(item.id),
            tooltip: 'Delete Food Log Entry',
          ),
        ],
      ),
    );
  }
}
