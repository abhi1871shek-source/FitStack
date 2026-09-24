import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/diet_preference_provider.dart';
import 'diet_weekly_plan_screen.dart';

class DietPreferenceScreen extends ConsumerStatefulWidget {
  const DietPreferenceScreen({super.key});

  @override
  ConsumerState<DietPreferenceScreen> createState() =>
      _DietPreferenceScreenState();
}

class _DietPreferenceScreenState extends ConsumerState<DietPreferenceScreen> {
  bool _editingCalories = false;
  late TextEditingController _calorieController;

  static const List<String> _allCuisines = [
    'Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese',
  ];

  static const List<String> _dietaryTypes = [
    'Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController();
  }

  @override
  void dispose() {
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(dietPreferenceProvider);
    final notifier = ref.read(dietPreferenceProvider.notifier);
    final onboarding = ref.watch(onboardingProvider);
    final goal = onboarding.primaryGoal ?? 'Maintain';
    final calorieTarget = prefs.calorieTarget ?? 1800;

    if (!_editingCalories) {
      _calorieController.text = calorieTarget.toString();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Diet Preferences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.66,
                minHeight: 4,
                backgroundColor: AppColors.surfaceSubdued,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              children: [
                // Header
                const Text(
                  "Let's plan your diet",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tell us what you like to eat — we'll build your weekly plan around it.",
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),

                // ── Cuisine Preference ──
                _sectionLabel('Cuisine Preference', trailing: 'Select multiple'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allCuisines.map((cuisine) {
                    final isSelected = prefs.selectedCuisines.contains(cuisine);
                    return GestureDetector(
                      onTap: () => notifier.toggleCuisine(cuisine),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.borderSubdued,
                            width: isSelected ? 0 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              cuisine,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // ── Dietary Type ──
                _sectionLabel('Dietary Type'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.2,
                  children: _dietaryTypes.map((type) {
                    // Normalise: 'Non-Vegetarian' → 'non-vegetarian'
                    final normalised = type.toLowerCase().replaceAll(' ', '-');
                    final isActive = prefs.dietaryType == normalised;
                    return GestureDetector(
                      onTap: () => notifier.setDietaryType(normalised),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accentSubtle : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? AppColors.primary : AppColors.borderSubdued,
                            width: isActive ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isActive) ...[
                              const Icon(Icons.check_circle, size: 15, color: AppColors.primary),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                type,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // ── Daily Calorie Target ──
                _sectionLabel('Daily Calorie Target'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubdued),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _editingCalories
                                ? TextField(
                                    controller: _calorieController,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      suffix: Text(' kcal/day',
                                          style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                                    ),
                                    onSubmitted: (v) {
                                      final val = int.tryParse(v);
                                      if (val != null) notifier.setCalorieTarget(val);
                                      setState(() => _editingCalories = false);
                                    },
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatCalories(calorieTarget),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text('kcal / day',
                                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                                    ],
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              _editingCalories ? Icons.check_circle : Icons.edit_outlined,
                              color: _editingCalories ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              if (_editingCalories) {
                                final val = int.tryParse(_calorieController.text);
                                if (val != null) notifier.setCalorieTarget(val);
                              } else {
                                _calorieController.text = calorieTarget.toString();
                              }
                              setState(() => _editingCalories = !_editingCalories);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.borderSubdued),
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'Based on your goal: ',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          Text(
                            goal,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          if (prefs.isCalorieManuallyOverridden)
                            GestureDetector(
                              onTap: () {
                                notifier.resetCalorieToCalculated();
                                setState(() => _editingCalories = false);
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      if (prefs.isCalorieManuallyOverridden) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.edit, size: 13, color: AppColors.textMuted),
                            SizedBox(width: 4),
                            Text('Manually set', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Meals per Day ──
                _sectionLabel('Meals per Day'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubdued,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubdued),
                  ),
                  child: Row(
                    children: [3, 4, 5].map((count) {
                      final isSelected = prefs.mealsPerDay == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.setMealsPerDay(count),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.cardSurface : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              border: isSelected
                                  ? Border.all(color: AppColors.borderSubdued)
                                  : null,
                              boxShadow: isSelected
                                  ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1))]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$count meals',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mealScheduleHint(prefs.mealsPerDay),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // CTA Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DietWeeklyPlanScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Text('Generate My Plan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                label: const Icon(Icons.arrow_forward, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        if (trailing != null)
          Text(trailing, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      return '${(cal ~/ 1000)},${(cal % 1000).toString().padLeft(3, '0')}';
    }
    return cal.toString();
  }

  String _mealScheduleHint(int meals) {
    switch (meals) {
      case 3:
        return 'Breakfast, Lunch & Dinner.';
      case 5:
        return 'Breakfast, Lunch, two Snacks & Dinner scheduled around workouts.';
      default:
        return 'Breakfast, Lunch, Evening Snack & Dinner scheduled around workouts.';
    }
  }
}
