import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/emoji_progress_bar.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import 'workout_add_library_screen.dart';
import 'workout_quick_edit_sheet.dart';
import 'workout_weekly_plan_screen.dart';

class WorkoutTodayScreen extends ConsumerStatefulWidget {
  const WorkoutTodayScreen({super.key});

  @override
  ConsumerState<WorkoutTodayScreen> createState() => _WorkoutTodayScreenState();
}

class _WorkoutTodayScreenState extends ConsumerState<WorkoutTodayScreen> {
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutProvider);
    final workoutLogs = workoutState.logs;
    final notifier = ref.read(workoutProvider.notifier);

    final isMobile = MediaQuery.of(context).size.width < 600;

    final pendingLogs = workoutLogs.where((l) => !l.isCompleted).toList();
    final completedLogs = workoutLogs.where((l) => l.isCompleted).toList();

    final totalCompleted = completedLogs.length;
    final totalCount = workoutLogs.length;
    final progress = totalCount > 0 ? totalCompleted / totalCount : 0.0;

    final bgColor = AppColors.ofBackground(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);

    if (workoutState.isLoading && workoutLogs.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Group pending exercises by muscle group
    final Map<String, List<WorkoutLogItem>> groupedPending = {};
    for (final log in pendingLogs) {
      groupedPending.putIfAbsent(log.muscleGroup, () => []).add(log);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & Progress Overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Workout",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Today, Oct 14 • $totalCompleted of $totalCount completed',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkoutWeeklyPlanScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_month_outlined, size: 22, color: AppColors.primary),
                            tooltip: 'Weekly Plan',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accentSubtle,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WorkoutAddLibraryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 22, color: AppColors.primary),
                            tooltip: 'Add Exercises',
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

                  // Emoji Progress Bar (💪)
                  EmojiProgressBar(
                    progress: progress,
                    emoji: '💪',
                    height: 8,
                    barColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            // Workout Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  // Gesture Hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          isMobile ? Icons.swipe : Icons.mouse,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMobile ? 'Swipe right to complete set' : 'Click check to complete set',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  if (workoutLogs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ofCardSurface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.ofBorderSubdued(context)),
                      ),
                      child: Text(
                        'No exercises logged for today! Tap + to browse library 💪',
                        style: TextStyle(color: AppColors.ofTextMuted(context), fontSize: 13),
                      ),
                    ),

                  // Pending Exercises Grouped by Muscle Group
                  ...groupedPending.entries.map((entry) {
                    final groupName = entry.key;
                    final items = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center, size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '$groupName Workout'.toUpperCase(),
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
                        ),
                        const SizedBox(height: 6),

                        // Exercise Cards in Group
                        ...items.map((log) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: isMobile
                                ? _buildMobileDismissibleCard(context, log, notifier)
                                : _buildWorkoutCard(context, log, notifier, isMobile: false),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),

                  // Completed Exercises Section
                  if (completedLogs.isNotEmpty) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showCompleted = !_showCompleted;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'COMPLETED EXERCISES (${completedLogs.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  _showCompleted ? 'Hide' : 'Show',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Icon(
                                  _showCompleted ? Icons.expand_less : Icons.expand_more,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_showCompleted)
                      ...completedLogs.map((log) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: isMobile
                              ? _buildMobileDismissibleCard(context, log, notifier)
                              : _buildWorkoutCard(context, log, notifier, isMobile: false),
                        );
                      }),
                  ],

                  const SizedBox(height: 80), // Padding above FAB
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button (+) to open Exercise Library
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkoutAddLibraryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Add Workout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Mobile Swipe Dismissible Wrapper
  Widget _buildMobileDismissibleCard(
    BuildContext context,
    WorkoutLogItem log,
    WorkoutNotifier notifier,
  ) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          notifier.toggleComplete(log.id, true);
        } else if (direction == DismissDirection.endToStart) {
          notifier.toggleComplete(log.id, false);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.accentSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Set Completed',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubdued,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubdued),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Undo',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.undo, color: AppColors.textMuted, size: 24),
          ],
        ),
      ),
      child: _buildWorkoutCard(context, log, notifier, isMobile: true),
    );
  }

  // Workout Card Core
  Widget _buildWorkoutCard(
    BuildContext context,
    WorkoutLogItem log,
    WorkoutNotifier notifier, {
    required bool isMobile,
  }) {
    return InkWell(
      onTap: () => _openQuickEditModal(context, log),
      onLongPress: () => _showOptionsBottomSheet(context, log),
      onSecondaryTap: () => _showOptionsBottomSheet(context, log),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: log.isCompleted ? AppColors.ofSurfaceSubdued(context).withOpacity(0.7) : AppColors.ofCardSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: log.isCompleted ? AppColors.ofBorderSubdued(context).withOpacity(0.5) : AppColors.ofBorderSubdued(context),
          ),
          boxShadow: log.isCompleted
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Left Accent Strip for Active Items
            if (!log.isCompleted)
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Checkbox Button
            InkWell(
              onTap: () => notifier.toggleComplete(log.id),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: log.isCompleted ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: log.isCompleted ? AppColors.primary : AppColors.borderSubdued,
                    width: 1.8,
                  ),
                ),
                child: log.isCompleted
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),

            // Exercise Thumbnail Image
            if (log.imageUrl != null && log.imageUrl!.isNotEmpty) ...[
              InkWell(
                onTap: () => showImagePreviewDialog(context, log.imageUrl!, log.name),
                onDoubleTap: () => showImagePreviewDialog(context, log.imageUrl!, log.name),
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: log.imageUrl!.startsWith('http')
                      ? Image.network(
                          log.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 44,
                            height: 44,
                            color: AppColors.surfaceSubdued,
                            child: const Icon(Icons.fitness_center, size: 20, color: AppColors.textMuted),
                          ),
                        )
                      : Image.asset(
                          log.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 44,
                            height: 44,
                            color: AppColors.surfaceSubdued,
                            child: const Icon(Icons.fitness_center, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Exercise Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: log.isCompleted ? AppColors.ofTextMuted(context) : AppColors.ofTextPrimary(context),
                      decoration: log.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${log.sets} sets × ${log.reps} reps',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(fontSize: 10, color: AppColors.ofTextMuted(context))),
                      const SizedBox(width: 8),
                      Text(
                        log.weightKg > 0 ? '${log.weightKg.toStringAsFixed(0)} kg' : 'Bodyweight',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: log.isCompleted ? AppColors.ofTextMuted(context) : AppColors.ofTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Desktop Explicit Edit & Delete Actions
            if (!isMobile) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                onPressed: () => _openQuickEditModal(context, log),
                tooltip: 'Quick Edit Sets/Reps/Weight',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                onPressed: () => notifier.deleteExercise(log.id),
                tooltip: 'Delete Exercise',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                onPressed: () => _openQuickEditModal(context, log),
                tooltip: 'Edit',
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openQuickEditModal(BuildContext context, WorkoutLogItem log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutQuickEditSheet(item: log),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, WorkoutLogItem log) {
    final notifier = ref.read(workoutProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ofCardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ofTextPrimary(context)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Quick Edit Sets/Reps/Weight'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openQuickEditModal(context, log);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                  title: Text(log.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed'),
                  onTap: () {
                    Navigator.pop(ctx);
                    notifier.toggleComplete(log.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  title: const Text('Delete Exercise', style: TextStyle(color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(ctx);
                    notifier.deleteExercise(log.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
