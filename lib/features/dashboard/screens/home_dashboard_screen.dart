import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/animated_streak_counter.dart';
import '../../../core/widgets/emoji_progress_bar.dart';
import '../../../navigation/providers/navigation_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../diet/providers/diet_preference_provider.dart';
import '../../diet/providers/food_log_provider.dart';
import '../../diet/screens/quick_add_food_sheet.dart';
import '../../habits/models/habit_item.dart';
import '../../habits/providers/habits_provider.dart';
import '../../profile/screens/settings_screen.dart';
import '../../progress/providers/step_count_provider.dart';
import '../../workout/models/exercise.dart';
import '../../workout/providers/workout_provider.dart';
import '../../workout/screens/workout_add_library_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  TimeOfDay _defaultTimeForSection(String timeOfDay) {
    switch (timeOfDay) {
      case 'Morning':
        return const TimeOfDay(hour: 7, minute: 0);
      case 'Afternoon':
        return const TimeOfDay(hour: 13, minute: 0);
      case 'Evening':
      default:
        return const TimeOfDay(hour: 18, minute: 0);
    }
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String timeOfDay = 'Morning';
    String category = 'Routine';
    TimeOfDay? selectedTime = _defaultTimeForSection('Morning');
    int? reminderMinutes = 10;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Add New Habit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Habit Title',
                        hintText: 'e.g. Afternoon 20m Walk',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: timeOfDay,
                      items: ['Morning', 'Afternoon', 'Evening']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            timeOfDay = val;
                            selectedTime = _defaultTimeForSection(val);
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Time of Day'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ['Routine', 'Workout', 'Nutrition', 'Habits']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    // Interactive Time Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? _defaultTimeForSection(timeOfDay),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubdued,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubdued),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Scheduled Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                              ),
                              child: Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Pick Time',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reminder Offset Selector
                    DropdownButtonFormField<int?>(
                      value: reminderMinutes,
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No reminder'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 5,
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('5 minutes before'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<int?>(
                          value: 10,
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('10 minutes before'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        setDialogState(() => reminderMinutes = val);
                        if (val != null) {
                          await NotificationService.instance.requestPermission(context);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Local Reminder Notification',
                        helperText: 'Fires before scheduled habit time',
                        helperStyle: TextStyle(fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Goal / Target (optional)',
                        hintText: 'e.g. 3,000 steps or 20 mins',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      final formattedTime = selectedTime?.format(context);
                      ref.read(habitsProvider.notifier).addHabit(
                            title: title,
                            timeOfDay: timeOfDay,
                            category: category,
                            time: formattedTime,
                            subtitle: subtitleController.text.trim().isEmpty
                                ? null
                                : subtitleController.text.trim(),
                            reminderMinutesBefore: reminderMinutes,
                            scheduledHour: selectedTime?.hour,
                            scheduledMinute: selectedTime?.minute,
                          );
                    }
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Habit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openQuickAddFood(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddFoodSheet(),
    );
  }

  void _openAddWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutAddLibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final habits = ref.watch(habitsListProvider);
    final workouts = ref.watch(workoutListProvider);
    final foodLogs = ref.watch(foodLogListProvider);
    final dietPrefs = ref.watch(dietPreferenceProvider);
    final stepCount = ref.watch(stepCountProvider);

    // 1. Habits metrics
    final completedHabits = habits.where((h) => h.isCompleted).toList();
    final int habitsTotal = habits.length;
    final int habitsCompleted = completedHabits.length;
    final double habitsRatio = habitsTotal > 0 ? habitsCompleted / habitsTotal : 0.0;
    final int habitsPercent = (habitsRatio * 100).round();

    // 2. Workout metrics
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    final int workoutsTotal = workouts.length;
    final int workoutsCompleted = completedWorkouts.length;
    final double workoutRatio = workoutsTotal > 0 ? workoutsCompleted / workoutsTotal : 0.0;
    final int workoutPercent = (workoutRatio * 100).round();
    final Set<String> muscleGroups = workouts.map((w) => w.muscleGroup).toSet();
    final String workoutFocus = muscleGroups.isNotEmpty ? muscleGroups.take(2).join(' & ') : 'General Routine';

    // 3. Diet metrics
    final double caloriesLogged = foodLogs.fold(0.0, (sum, item) => sum + item.calories);
    final int calorieTarget = (dietPrefs.calorieTarget != null && dietPrefs.calorieTarget! > 0)
        ? dietPrefs.calorieTarget!
        : 2350;
    final double dietRatio = calorieTarget > 0 ? (caloriesLogged / calorieTarget).clamp(0.0, 1.0) : 0.0;
    final int dietPercent = (dietRatio * 100).round();

    // Macros summary
    final double totalProtein = foodLogs.fold(0.0, (sum, item) => sum + item.proteinGrams);
    final double totalCarbs = foodLogs.fold(0.0, (sum, item) => sum + item.carbsGrams);
    final double totalFat = foodLogs.fold(0.0, (sum, item) => sum + item.fatGrams);

    // 4. Overall Progress
    final double overallProgress = (habitsRatio + workoutRatio + dietRatio) / 3.0;
    final int overallPercent = (overallProgress * 100).round();

    // Streak
    final int currentStreak = completedHabits.isNotEmpty
        ? completedHabits.map((h) => h.streakDays).fold(0, math.max)
        : 0;

    // Date String
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    final bgColor = AppColors.ofBackground(context);
    final cardColor = AppColors.ofCardSurface(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final borderColor = AppColors.ofBorderSubdued(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Greeting & Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user?.displayName ?? 'Alex'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr • Daily Overview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: textMutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(navigationProvider.notifier).setTab(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: Colors.orangeAccent, size: 16),
                              const SizedBox(width: 4),
                              AnimatedStreakCounter(
                                count: currentStreak > 0 ? currentStreak : 14,
                                suffix: 'd Streak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile / Account Menu with Logout
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
                        ),
                        tooltip: 'Account Settings & Theme',
                        offset: const Offset(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: cardColor,
                        onSelected: (val) {
                          if (val == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          } else if (val == 'theme') {
                            ref.read(themeProvider.notifier).toggleTheme();
                          } else if (val == 'logout') {
                            ref.read(authProvider.notifier).logout();
                          }
                        },
                        itemBuilder: (ctx) {
                          final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                          return [
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'FitStack Athlete',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textMutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(Icons.settings_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Settings',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'theme',
                              child: Row(
                                children: [
                                  Icon(
                                    isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
                                    size: 18,
                                    color: isDark ? AppColors.metricGreen : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Dark Mode',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Quick-Add Action Buttons Row
              _buildQuickActionsRow(context),

              const SizedBox(height: 20),

              // 3. Today's Habits Card
              _buildHabitsCard(
                context: context,
                habits: habits,
                habitsCompleted: habitsCompleted,
                habitsTotal: habitsTotal,
                habitsRatio: habitsRatio,
                habitsPercent: habitsPercent,
                onTapViewAll: () => ref.read(navigationProvider.notifier).setTab(1),
              ),

              const SizedBox(height: 16),

              // 4. Today's Workout Card
              _buildWorkoutCard(
                context: context,
                workouts: workouts,
                focus: workoutFocus,
                workoutsCompleted: workoutsCompleted,
                workoutsTotal: workoutsTotal,
                workoutRatio: workoutRatio,
                workoutPercent: workoutPercent,
                onTapViewAll: () => ref.read(navigationProvider.notifier).setTab(4),
              ),

              const SizedBox(height: 16),

              // 5. Calories & Nutrition Card
              _buildDietCard(
                context: context,
                caloriesLogged: caloriesLogged.round(),
                calorieTarget: calorieTarget,
                dietRatio: dietRatio,
                dietPercent: dietPercent,
                proteinGrams: totalProtein.round(),
                carbsGrams: totalCarbs.round(),
                fatGrams: totalFat.round(),
                onTapViewAll: () => ref.read(navigationProvider.notifier).setTab(3),
              ),

              const SizedBox(height: 16),

              // 6. Overall Telemetry Progress Card
              _buildOverallProgressCard(
                context: context,
                overallPercent: overallPercent,
                overallProgress: overallProgress,
                stepCount: stepCount,
                onTapProgress: () => ref.read(navigationProvider.notifier).setTab(2),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Quick Action Shortcut Buttons Row
  Widget _buildQuickActionsRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK SHORTCUTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: context.txtMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                label: '+ Habit',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
                onTap: () => _showAddHabitDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                label: '+ Workout',
                icon: Icons.fitness_center,
                color: const Color(0xFF3B82F6),
                onTap: () => _openAddWorkout(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context: context,
                label: '+ Food',
                icon: Icons.restaurant,
                color: const Color(0xFFF59E0B),
                onTap: () => _openQuickAddFood(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Today's Habits Card
  Widget _buildHabitsCard({
    required BuildContext context,
    required List<HabitItem> habits,
    required int habitsCompleted,
    required int habitsTotal,
    required double habitsRatio,
    required int habitsPercent,
    required VoidCallback onTapViewAll,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final surfaceSubduedColor = AppColors.ofSurfaceSubdued(context);

    // Show top 3 pending or first habits
    final previewHabits = habits.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: surfaceSubduedColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Habits",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor),
                      ),
                      Text(
                        '$habitsCompleted of $habitsTotal completed',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: habitsPercent >= 100 ? const Color(0xFFD1FAE5) : surfaceSubduedColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$habitsPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reused animated EmojiProgressBar
          EmojiProgressBar(
            progress: habitsRatio,
            emoji: '🎯',
            height: 7,
          ),

          const SizedBox(height: 14),

          // Compact habit rows preview with live interactive checkbox toggle
          ...previewHabits.map((habit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  ref.read(habitsProvider.notifier).toggleHabit(habit.id);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubdued.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        habit.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: habit.isCompleted ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                                color: habit.isCompleted ? textMutedColor : textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (habit.time != null || habit.subtitle != null)
                              Text(
                                '${habit.time ?? ''}${habit.time != null && habit.subtitle != null ? ' • ' : ''}${habit.subtitle ?? ''}',
                                style: TextStyle(fontSize: 10, color: textMutedColor),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          habit.timeOfDay,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ofTextSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Footer Tap-Through
          InkWell(
            onTap: onTapViewAll,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all $habitsTotal habits in To-Do',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Today's Workout Card
  Widget _buildWorkoutCard({
    required BuildContext context,
    required List<WorkoutLogItem> workouts,
    required String focus,
    required int workoutsCompleted,
    required int workoutsTotal,
    required double workoutRatio,
    required int workoutPercent,
    required VoidCallback onTapViewAll,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final surfaceSubduedColor = AppColors.ofSurfaceSubdued(context);

    final previewWorkouts = workouts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, color: Color(0xFF3B82F6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Today's Workout",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              focus,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$workoutsCompleted of $workoutsTotal exercises done',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: workoutPercent >= 100 ? const Color(0xFFD1FAE5) : surfaceSubduedColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$workoutPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reused animated EmojiProgressBar
          EmojiProgressBar(
            progress: workoutRatio,
            emoji: '💪',
            barColor: const Color(0xFF3B82F6),
            height: 7,
          ),

          const SizedBox(height: 14),

          // Compact workout exercises list with live toggle
          ...previewWorkouts.map((exercise) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  ref.read(workoutProvider.notifier).toggleComplete(exercise.id);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: surfaceSubduedColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        exercise.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: exercise.isCompleted ? const Color(0xFF3B82F6) : textMutedColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: exercise.isCompleted ? TextDecoration.lineThrough : null,
                                color: exercise.isCompleted ? textMutedColor : textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${exercise.sets} sets × ${exercise.reps} reps • ${exercise.weightKg.toStringAsFixed(0)} kg',
                              style: TextStyle(fontSize: 10, color: textMutedColor),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          exercise.muscleGroup,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.ofTextSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Footer Tap-Through
          InkWell(
            onTap: onTapViewAll,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Open Today's Workout",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFF1D4ED8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Calories & Nutrition Card
  Widget _buildDietCard({
    required BuildContext context,
    required int caloriesLogged,
    required int calorieTarget,
    required double dietRatio,
    required int dietPercent,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    required VoidCallback onTapViewAll,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final surfaceSubduedColor = AppColors.ofSurfaceSubdued(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFFD97706), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diet & Nutrition",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor),
                      ),
                      Text(
                        '${_formatNumber(caloriesLogged)} / ${_formatNumber(calorieTarget)} kcal eaten',
                        style: TextStyle(fontSize: 11, color: textMutedColor),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dietPercent >= 100 ? const Color(0xFFD1FAE5) : surfaceSubduedColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$dietPercent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reused animated EmojiProgressBar
          EmojiProgressBar(
            progress: dietRatio,
            emoji: '🥗',
            assetPath: 'assets/images/emoji/emoji_salad.png',
            barColor: const Color(0xFFD97706),
            height: 7,
          ),

          const SizedBox(height: 14),

          // Macro Breakdown Pills Row
          Row(
            children: [
              Expanded(
                child: _buildMacroBadge(
                  context: context,
                  label: 'Protein',
                  value: '${proteinGrams}g',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  context: context,
                  label: 'Carbs',
                  value: '${carbsGrams}g',
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBadge(
                  context: context,
                  label: 'Fats',
                  value: '${fatGrams}g',
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer Tap-Through
          InkWell(
            onTap: onTapViewAll,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open Food Log & Details',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    final textMutedColor = AppColors.ofTextMuted(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final surfaceSubduedColor = AppColors.ofSurfaceSubdued(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceSubduedColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: textMutedColor)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Overall Telemetry Progress Card
  Widget _buildOverallProgressCard({
    required BuildContext context,
    required int overallPercent,
    required double overallProgress,
    required int stepCount,
    required VoidCallback onTapProgress,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final surfaceSubduedColor = AppColors.ofSurfaceSubdued(context);

    return InkWell(
      onTap: onTapProgress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.show_chart, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Daily Adherence',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      Text(
                        '$overallPercent%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: surfaceSubduedColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Steps: ${_formatNumber(stepCount)} logged today • Tap for Telemetry',
                    style: TextStyle(fontSize: 10, color: textMutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: textMutedColor),
          ],
        ),
      ),
    );
  }
}
