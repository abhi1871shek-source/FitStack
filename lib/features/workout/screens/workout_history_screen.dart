import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image_widget.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const WorkoutHistoryScreen({super.key, this.initialDate});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  List<WorkoutLogItem> _logs = [];

  @override
  void initState() {
    super.initState();
    // Default to yesterday if not provided, or initialDate
    _selectedDate = widget.initialDate ?? DateTime.now().subtract(const Duration(days: 1));
    _loadHistoryForDate(_selectedDate);
  }

  Future<void> _loadHistoryForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _selectedDate = date;
    });

    final notifier = ref.read(workoutProvider.notifier);
    final logs = await notifier.fetchLogsForDate(date);

    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayStr = '${weekdayNames[date.weekday - 1]}, ${monthNames[date.month - 1]} ${date.day}, ${date.year}';

    if (target.isAtSameMomentAs(today)) {
      return 'Today • $dayStr';
    } else if (target.isAtSameMomentAs(yesterday)) {
      return 'Yesterday • $dayStr';
    }
    return dayStr;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _loadHistoryForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.ofBackground(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);

    final completedCount = _logs.where((l) => l.isCompleted).length;
    final totalCount = _logs.length;
    final totalSetsCompleted = _logs
        .where((l) => l.isCompleted)
        .fold<int>(0, (sum, item) => sum + item.effectiveSets);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: textPrimaryColor),
        title: Text(
          'Workout History',
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Selector Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: cardColor,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _loadHistoryForDate(_selectedDate.subtract(const Duration(days: 1)));
                    },
                    icon: const Icon(Icons.chevron_left, size: 24),
                    tooltip: 'Previous Day',
                    style: IconButton.styleFrom(
                      backgroundColor: bgColor,
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accentSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _formatDateHeader(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _loadHistoryForDate(_selectedDate.add(const Duration(days: 1)));
                    },
                    icon: const Icon(Icons.chevron_right, size: 24),
                    tooltip: 'Next Day',
                    style: IconButton.styleFrom(
                      backgroundColor: bgColor,
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadHistoryForDate(_selectedDate),
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          if (_logs.isNotEmpty) ...[
                            // Summary Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('Logged', '$totalCount exercises', textPrimaryColor),
                                  Container(height: 24, width: 1, color: borderColor),
                                  _buildStatColumn('Completed', '$completedCount / $totalCount', AppColors.primary),
                                  Container(height: 24, width: 1, color: borderColor),
                                  _buildStatColumn('Total Sets', '$totalSetsCompleted sets', textPrimaryColor),
                                ],
                              ),
                            ),

                            // Logged Exercises Header
                            Row(
                              children: [
                                const Icon(Icons.history, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Logged Exercises',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // List of Logged Workout Cards
                            ..._logs.map((log) => _buildReadOnlyWorkoutCard(context, log)),
                          ] else
                            // Empty State Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                              margin: const EdgeInsets.only(top: 20),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSubtle,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center_outlined,
                                      size: 36,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No workout logged on this day',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Select another date using the calendar controls above to view past workouts.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.ofTextMuted(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.ofTextMuted(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyWorkoutCard(BuildContext context, WorkoutLogItem log) {
    final cardColor = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final bgColor = AppColors.ofBackground(context);

    final setDetailsList = log.setDetails.isNotEmpty
        ? log.setDetails
        : List.generate(
            log.sets,
            (i) => ExerciseSet(setNumber: i + 1, reps: log.reps, weightKg: log.weightKg),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: log.isCompleted ? AppColors.primary.withOpacity(0.3) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Thumbnail Image
                GestureDetector(
                  onTap: () {
                    if (log.effectiveImageUrl != null && log.effectiveImageUrl!.isNotEmpty) {
                      showImagePreviewDialog(context, log.effectiveImageUrl!, log.name);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AppImageWidget(
                      imagePath: log.effectiveImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.fitness_center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentSubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.muscleGroup,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.repsAndWeightSummary,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.ofTextMuted(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Completion Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: log.isCompleted
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.ofBorderSubdued(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: log.isCompleted
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.ofBorderSubdued(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        log.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 13,
                        color: log.isCompleted ? AppColors.primary : AppColors.ofTextMuted(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: log.isCompleted ? AppColors.primary : AppColors.ofTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Per-Set Details List (Read-Only)
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per-Set Performance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ofTextMuted(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: setDetailsList.map((set) {
                    final weightStr = set.weightKg == set.weightKg.roundToDouble()
                        ? set.weightKg.round().toString()
                        : set.weightKg.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Set ${set.setNumber}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${set.reps} reps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                          ),
                          Text(
                            ' × ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ofTextMuted(context),
                            ),
                          ),
                          Text(
                            '$weightStr kg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
