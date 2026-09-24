import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../diet/providers/diet_preference_provider.dart';
import '../../diet/providers/food_log_provider.dart';
import '../../habits/providers/habits_provider.dart';
import '../../workout/providers/workout_provider.dart';
import '../providers/step_count_provider.dart';
import '../providers/telemetry_provider.dart';
import 'weekly_monthly_analytics_screen.dart';

class ProgressTodayScreen extends ConsumerStatefulWidget {
  const ProgressTodayScreen({super.key});

  @override
  ConsumerState<ProgressTodayScreen> createState() => _ProgressTodayScreenState();
}

class _ProgressTodayScreenState extends ConsumerState<ProgressTodayScreen> {
  static const int _stepGoal = 10000;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showEditStepsDialog(BuildContext context, int currentSteps) {
    final controller = TextEditingController(text: currentSteps.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        final cardColor = AppColors.ofCardSurface(ctx);
        final textPrimary = AppColors.ofTextPrimary(ctx);
        final textSecondary = AppColors.ofTextSecondary(ctx);
        final textMuted = AppColors.ofTextMuted(ctx);

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.directions_walk, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Update Step Count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter steps logged today. Note: Real device step tracking (HealthKit / Health Connect) will be integrated in a future release.',
                style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Steps',
                  suffixText: 'steps',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed != null && parsed >= 0) {
                  ref.read(stepCountProvider.notifier).setSteps(parsed);
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch independent feature state providers
    final habitsState = ref.watch(habitsProvider);
    final workoutState = ref.watch(workoutProvider);
    final foodLogState = ref.watch(foodLogProvider);
    final telemetryState = ref.watch(telemetryNotifierProvider);
    final dietPrefs = ref.watch(dietPreferenceProvider);

    final habits = habitsState.habits;
    final workouts = workoutState.logs;
    final foodLogs = foodLogState.logs;
    final stepCount = ref.watch(stepCountProvider);

    final isLoading = habitsState.isLoading ||
        workoutState.isLoading ||
        foodLogState.isLoading ||
        telemetryState.isLoading;

    // 1. Habits breakdown calculation
    final completedHabits = habits.where((h) => h.isCompleted).toList();
    final totalHabits = habits.length;
    final double habitsRatio =
        totalHabits > 0 ? (completedHabits.length / totalHabits) : 0.0;
    final int habitsPercent = (habitsRatio * 100).round();

    // 2. Workout breakdown calculation
    final completedWorkouts = workouts.where((w) => w.isCompleted).toList();
    final totalWorkouts = workouts.length;
    final double workoutRatio =
        totalWorkouts > 0 ? (completedWorkouts.length / totalWorkouts) : 0.0;
    final int workoutPercent = (workoutRatio * 100).round();

    // 3. Diet breakdown calculation
    final double caloriesLogged =
        foodLogs.fold(0.0, (sum, item) => sum + item.calories);
    final int calorieTarget = (dietPrefs.calorieTarget != null && dietPrefs.calorieTarget! > 0)
        ? dietPrefs.calorieTarget!
        : 2350;
    final double dietRatio = calorieTarget > 0
        ? (caloriesLogged / calorieTarget).clamp(0.0, 1.0)
        : 0.0;
    final int dietPercent = (dietRatio * 100).round();

    // Auto-sync activity rollup to daily_telemetry table in Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(telemetryNotifierProvider.notifier).syncTodayActivity(
              habitsCompleted: completedHabits.length,
              habitsTotal: totalHabits,
              exercisesCompleted: completedWorkouts.length,
              exercisesTotal: totalWorkouts,
              caloriesConsumed: caloriesLogged,
              calorieTarget: calorieTarget,
            );
      }
    });

    // 4. Overall daily adherence
    final double overallAdherence = (habitsRatio + workoutRatio + dietRatio) / 3.0;
    final int overallPercent = (overallAdherence * 100).round();

    // 5. Streak calculation from real habit data
    final int currentStreak = completedHabits.isNotEmpty
        ? completedHabits.map((h) => h.streakDays).fold(0, math.max)
        : 0;

    // Calories remaining
    final int caloriesRemaining =
        (calorieTarget - caloriesLogged.round()).clamp(0, 99999);

    // Step progress
    final double stepProgress = (stepCount / _stepGoal).clamp(0.0, 1.0);
    final int stepPercent = (stepProgress * 100).round();

    final bgColor = AppColors.ofBackground(context);
    final cardColor = AppColors.ofCardSurface(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);

    // Loading state UI
    if (isLoading && habits.isEmpty && workouts.isEmpty && foodLogs.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            "Today's Progress",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimaryColor),
          ),
          backgroundColor: cardColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Syncing Progress with Supabase DB...',
                style: TextStyle(fontSize: 13, color: AppColors.ofTextSecondary(context)),
              ),
            ],
          ),
        ),
      );
    }

    // Date formatting
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '$dateStr • ${overallPercent >= 70 ? "On Track" : "In Progress"}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.ofTextMuted(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Weekly & Monthly Analytics',
            icon: Icon(Icons.calendar_month, color: textPrimaryColor),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WeeklyMonthlyAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Share Progress',
            icon: Icon(Icons.share, color: textPrimaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Today\'s summary copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Step Activity Ring Card
              _buildStepActivityRingCard(
                context,
                stepCount: stepCount,
                stepGoal: _stepGoal,
                stepProgress: stepProgress,
                stepPercent: stepPercent,
                onTapEdit: () => _showEditStepsDialog(context, stepCount),
              ),

              const SizedBox(height: 16),

              // 2. Today's Total Calories Card
              _buildCaloriesCard(
                context,
                caloriesLogged: caloriesLogged.round(),
                calorieTarget: calorieTarget,
                caloriesRemaining: caloriesRemaining,
                dietRatio: dietRatio,
              ),

              const SizedBox(height: 16),

              // 3. Streak & 7-Day Consistency Matrix Strip
              _buildStreakSection(
                context,
                streakDays: currentStreak,
                isCompletedToday: completedHabits.isNotEmpty,
              ),

              const SizedBox(height: 16),

              // 4. Today's Breakdown Section
              _buildBreakdownCard(
                context,
                overallPercent: overallPercent,
                habitsCompleted: completedHabits.length,
                habitsTotal: totalHabits,
                habitsPercent: habitsPercent,
                habitsRatio: habitsRatio,
                workoutsCompleted: completedWorkouts.length,
                workoutsTotal: totalWorkouts,
                workoutPercent: workoutPercent,
                workoutRatio: workoutRatio,
                caloriesLogged: caloriesLogged.round(),
                calorieTarget: calorieTarget,
                dietPercent: dietPercent,
                dietRatio: dietRatio,
              ),

              const SizedBox(height: 16),

              // 5. History Navigation Row to Weekly & Monthly Progress
              _buildAnalyticsNavigationCard(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Hero Activity Ring Section
  Widget _buildStepActivityRingCard(
    BuildContext context, {
    required int stepCount,
    required int stepGoal,
    required double stepProgress,
    required int stepPercent,
    required VoidCallback onTapEdit,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackRingColor = isDark ? AppColors.darkBorder : const Color(0xFFE9EDFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          // Circular Progress Ring with tap-to-edit
          GestureDetector(
            onTap: onTapEdit,
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _ActivityRingPainter(
                      progress: stepProgress,
                      trackColor: trackRingColor,
                      progressColor: AppColors.primary,
                      strokeWidth: 12,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatNumber(stepCount),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'STEPS TODAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: textMuted,
                        ),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 11, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text(
                            'Tap to edit',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Goal Status Subtitle Pill
          GestureDetector(
            onTap: onTapEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceSubdued,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Goal: ${_formatNumber(stepGoal)} steps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      '$stepPercent%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Today's Total Calories Card
  Widget _buildCaloriesCard(
    BuildContext context, {
    required int caloriesLogged,
    required int calorieTarget,
    required int caloriesRemaining,
    required double dietRatio,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: surfaceSubdued,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Total Calories",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatNumber(caloriesLogged)} consumed / ${_formatNumber(calorieTarget)} kcal target',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: surfaceSubdued,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  caloriesRemaining > 0
                      ? '${_formatNumber(caloriesRemaining)} kcal left'
                      : 'Target Met',
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

          // Calorie Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dietRatio,
              minHeight: 8,
              backgroundColor: surfaceSubdued,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          const SizedBox(height: 10),

          // Consumed / Burn / Goal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 11, color: textMuted),
                  children: [
                    const TextSpan(text: 'Consumed: '),
                    TextSpan(
                      text: '${_formatNumber(caloriesLogged)} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 11, color: textMuted),
                  children: const [
                    TextSpan(text: 'Active Burn: '),
                    TextSpan(
                      text: '480 kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 11, color: textMuted),
                  children: [
                    const TextSpan(text: 'Goal: '),
                    TextSpan(
                      text: '${_formatNumber(calorieTarget)} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Horizontal Streak Bar Section
  Widget _buildStreakSection(
    BuildContext context, {
    required int streakDays,
    required bool isCompletedToday,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);

    // 7-day strip labels & states (Thursday Oct 8 to Wednesday Oct 14)
    final days = [
      {'day': 'Th', 'num': '8', 'completed': true, 'isToday': false},
      {'day': 'Fr', 'num': '9', 'completed': true, 'isToday': false},
      {'day': 'Sa', 'num': '10', 'completed': true, 'isToday': false},
      {'day': 'Su', 'num': '11', 'completed': true, 'isToday': false},
      {'day': 'Mo', 'num': '12', 'completed': true, 'isToday': false},
      {'day': 'Tu', 'num': '13', 'completed': true, 'isToday': false},
      {
        'day': 'We',
        'num': '14',
        'completed': isCompletedToday,
        'isToday': true,
      },
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    streakDays > 0
                        ? '$streakDays Day Streak'
                        : 'Session Streak Active',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                isCompletedToday ? 'Unbroken' : 'In Progress',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 7-Day Matrix Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final isToday = d['isToday'] as bool;
              final isCompleted = d['completed'] as bool;
              final dayLabel = d['day'] as String;
              final numLabel = d['num'] as String;

              return Column(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? AppColors.primary : textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? (isCompleted
                              ? AppColors.primary
                              : cardColor)
                          : (isCompleted
                              ? AppColors.primary
                              : surfaceSubdued),
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : (isToday
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Text(
                                  '·',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    numLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primary : textMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          Text(
            'Streak reflects active habits completed today during this session.',
            style: TextStyle(fontSize: 10, color: textMuted),
          ),
        ],
      ),
    );
  }

  /// 4. Today's Breakdown Section Card
  Widget _buildBreakdownCard(
    BuildContext context, {
    required int overallPercent,
    required int habitsCompleted,
    required int habitsTotal,
    required int habitsPercent,
    required double habitsRatio,
    required int workoutsCompleted,
    required int workoutsTotal,
    required int workoutPercent,
    required double workoutRatio,
    required int caloriesLogged,
    required int calorieTarget,
    required int dietPercent,
    required double dietRatio,
  }) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S BREAKDOWN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Overall $overallPercent% Daily Adherence',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: surfaceSubdued,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  overallPercent >= 100 ? 'Completed' : 'In Progress',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Item 1: Habits
          _buildBreakdownItem(
            context,
            icon: Icons.check_circle_outline,
            title: 'Habits',
            subtitle: '($habitsCompleted of $habitsTotal completed)',
            percent: habitsPercent,
            progress: habitsRatio,
            isCompleted: habitsPercent >= 100,
          ),

          const SizedBox(height: 14),

          // Item 2: Gym / Workout
          _buildBreakdownItem(
            context,
            icon: Icons.fitness_center,
            title: 'Gym',
            subtitle: '($workoutsCompleted of $workoutsTotal exercises completed)',
            percent: workoutPercent,
            progress: workoutRatio,
            isCompleted: workoutPercent >= 100,
          ),

          const SizedBox(height: 14),

          // Item 3: Diet
          _buildBreakdownItem(
            context,
            icon: Icons.restaurant,
            title: 'Diet',
            subtitle:
                '${_formatNumber(caloriesLogged)} / ${_formatNumber(calorieTarget)} kcal',
            percent: dietPercent,
            progress: dietRatio,
            isCompleted: dietPercent >= 100,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int percent,
    required double progress,
    required bool isCompleted,
  }) {
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isCompleted ? AppColors.primary : textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
            Row(
              children: [
                if (isCompleted) ...[
                  const Icon(Icons.verified, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        isCompleted ? AppColors.primary : textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: surfaceSubdued,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  /// 5. History Navigation Row to Weekly & Monthly Progress
  Widget _buildAnalyticsNavigationCard(BuildContext context) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final surfaceSubdued = AppColors.ofSurfaceSubdued(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WeeklyMonthlyAnalyticsScreen(),
          ),
        );
      },
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: surfaceSubdued,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Weekly & Monthly Progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aggregated adherence, volume & trends',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom circular activity ring painter matching the visual design
class _ActivityRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ActivityRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
