import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/weekly_plan_day.dart';
import '../models/workout_cycle_exercise.dart';
import '../providers/workout_weekly_plan_provider.dart';
import '../widgets/cycle_exercise_picker_modal.dart';
import '../widgets/edit_day_focus_dialog.dart';

class WorkoutWeeklyPlanScreen extends ConsumerWidget {
  const WorkoutWeeklyPlanScreen({super.key});

  void _showLoopSetupDialog(BuildContext context, WidgetRef ref) {
    int selectedCycles = ref.read(workoutWeeklyPlanProvider).totalCycles;
    if (selectedCycles < 2) selectedCycles = 2;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.repeat, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Configure Workout Loop',
                    style: TextStyle(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select how many weekly workout cycles you want to repeat indefinitely.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 28, color: AppColors.primary),
                        onPressed: selectedCycles > 2
                            ? () => setModalState(() => selectedCycles--)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubdued,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubdued),
                        ),
                        child: Text(
                          '$selectedCycles Cycles',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 28, color: AppColors.primary),
                        onPressed: selectedCycles < 6
                            ? () => setModalState(() => selectedCycles++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Example: Cycle 1 → Cycle 2 → ... → Cycle $selectedCycles → Cycle 1',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final notifier = ref.read(workoutWeeklyPlanProvider.notifier);
                    await notifier.setTotalCycles(selectedCycles);
                    await notifier.toggleLoop(true);
                  },
                  child: const Text('Enable Loop', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutWeeklyPlanProvider);
    final weeklyPlan = state.days;
    final notifier = ref.read(workoutWeeklyPlanProvider.notifier);

    // Calculate telemetry stats
    final activeTrainingDays = weeklyPlan.where((d) => !d.isRestDay).length;
    final completedDays = weeklyPlan.where((d) => d.isCompleted).length;
    final totalRestDays = weeklyPlan.where((d) => d.isRestDay).length;
    final adherencePercent = activeTrainingDays > 0
        ? ((completedDays / activeTrainingDays) * 100).round()
        : 100;

    final firstDay = weeklyPlan.isNotEmpty ? weeklyPlan.first : null;
    final lastDay = weeklyPlan.isNotEmpty ? weeklyPlan.last : null;
    final dateRangeStr = (firstDay != null && lastDay != null)
        ? 'Oct ${firstDay.dateNum} – Oct ${lastDay.dateNum} • $activeTrainingDays Workouts, $totalRestDays Rest Days'
        : 'Weekly Plan';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Today\'s Workout',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Weekly Plan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (state.isLoopEnabled) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CYCLE ${state.viewingCycleNumber}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1),
            Text(
              dateRangeStr,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Top-Right Loop Switch Badge Container
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isLoopEnabled ? AppColors.accentSubtle : AppColors.surfaceSubdued,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.isLoopEnabled ? AppColors.primary : AppColors.borderSubdued,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: state.isLoopEnabled ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isLoopEnabled ? 'Loop ON' : 'Loop OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: state.isLoopEnabled ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: state.isLoopEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val) {
                          _showLoopSetupDialog(context, ref);
                        } else {
                          notifier.toggleLoop(false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                children: [
                  // Prominent Top Loop Feature Control Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: state.isLoopEnabled
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: state.isLoopEnabled
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.borderSubdued,
                        width: state.isLoopEnabled ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  state.isLoopEnabled
                                      ? 'WORKOUT LOOP ACTIVE (${state.totalCycles} CYCLES)'
                                      : 'WORKOUT LOOP FEATURE',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  state.isLoopEnabled ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: state.isLoopEnabled ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: state.isLoopEnabled,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    if (val) {
                                      _showLoopSetupDialog(context, ref);
                                    } else {
                                      notifier.toggleLoop(false);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (!state.isLoopEnabled) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Turn ON Loop to build multi-week workout cycle templates (e.g., 2, 3, 4 cycles) that repeat indefinitely on real calendar weeks.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showLoopSetupDialog(context, ref),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.sync, size: 16),
                              label: const Text(
                                'Enable Workout Loop',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Cycle Template to View / Edit:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                              ),
                              TextButton.icon(
                                onPressed: () => _showLoopSetupDialog(context, ref),
                                icon: const Icon(Icons.settings, size: 13, color: AppColors.primary),
                                label: const Text(
                                  'Change Cycles',
                                  style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(state.totalCycles, (idx) {
                                final cycleNum = idx + 1;
                                final isSelected = state.viewingCycleNumber == cycleNum;
                                final isActiveWeek = state.activeCycleNumber == cycleNum;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Cycle $cycleNum'),
                                        if (isActiveWeek) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : AppColors.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'ACTIVE THIS WEEK',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? AppColors.primary : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: AppColors.surfaceSubdued,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                    onSelected: (_) {
                                      notifier.selectViewingCycle(cycleNum);
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Weekly Summary / Adherence Telemetry Card
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubdued),
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
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ADHERENCE TELEMETRY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$completedDays / $activeTrainingDays Complete',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$adherencePercent%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Weekly Adherence',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Target: $activeTrainingDays Days',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Active Training',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: activeTrainingDays > 0 ? (completedDays / activeTrainingDays).clamp(0.0, 1.0) : 1.0,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceSubdued,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.isLoopEnabled
                            ? 'CYCLE ${state.viewingCycleNumber} TEMPLATE'
                            : 'CYCLE PROGRESSION',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        state.isLoopEnabled
                            ? 'Looping Schedule'
                            : 'Standard Schedule',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Vertical 7-Day Stack
                  ...weeklyPlan.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;

                    final cycleKey = '${state.viewingCycleNumber}_$index';
                    final cycleExList = state.cycleExercisesMap[cycleKey] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildDayCard(
                        context: context,
                        day: day,
                        index: index,
                        state: state,
                        notifier: notifier,
                        cycleExercises: cycleExList,
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required WeeklyPlanDay day,
    required int index,
    required WorkoutWeeklyPlanState state,
    required WorkoutWeeklyPlanNotifier notifier,
    required List<WorkoutCycleExercise> cycleExercises,
  }) {
    final isLoop = state.isLoopEnabled;
    final cycleNum = state.viewingCycleNumber;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isToday && isLoop ? AppColors.primary : AppColors.borderSubdued,
          width: day.isToday && isLoop ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Date / Day Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: day.isToday ? AppColors.primary : AppColors.surfaceSubdued,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.shortName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: day.isToday ? Colors.white : AppColors.textMuted,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.dateNum}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: day.isToday ? Colors.white : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Day Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            day.focusTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: day.isRestDay ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (day.isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      day.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Day Focus Dialog
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                onPressed: () {
                  if (isLoop) {
                    _openEditCycleDayFocusDialog(context, day, index, cycleNum, notifier);
                  } else {
                    _openEditDialog(context, day, index, notifier);
                  }
                },
                tooltip: 'Edit Day Focus',
              ),
            ],
          ),

          // Cycle Exercises List (When Loop is ON)
          if (isLoop) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.borderSubdued),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cycleExercises.isNotEmpty
                      ? '${cycleExercises.length} EXERCISES CONFIGURED'
                      : (day.isRestDay ? 'REST DAY PROTOCOL' : 'NO EXERCISES SET YET'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CycleExercisePickerModal(
                        cycleNumber: cycleNum,
                        dayIndex: index,
                        dayName: day.dayName,
                        currentExercises: cycleExercises,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          cycleExercises.isEmpty ? 'Select Exercises' : 'Edit Exercises',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (cycleExercises.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cycleExercises.map((ex) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubdued,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubdued),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          ex.exerciseName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ex.targetSets}x${ex.targetReps}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _openEditDialog(
    BuildContext context,
    WeeklyPlanDay day,
    int index,
    WorkoutWeeklyPlanNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => EditDayFocusDialog(
        day: day,
        onSave: (newTitle, isRestDay) {
          notifier.updateDayFocus(
            index: index,
            newTitle: newTitle,
            isRestDay: isRestDay,
          );
        },
      ),
    );
  }

  void _openEditCycleDayFocusDialog(
    BuildContext context,
    WeeklyPlanDay day,
    int dayIndex,
    int cycleNumber,
    WorkoutWeeklyPlanNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => EditDayFocusDialog(
        day: day,
        onSave: (newTitle, isRestDay) {
          notifier.updateCycleDayFocus(
            cycleNumber: cycleNumber,
            dayIndex: dayIndex,
            newTitle: newTitle,
            isRestDay: isRestDay,
          );
        },
      ),
    );
  }
}
