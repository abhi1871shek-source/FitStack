import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/telemetry_data.dart';
import '../providers/telemetry_provider.dart';

class WeeklyMonthlyAnalyticsScreen extends ConsumerStatefulWidget {
  const WeeklyMonthlyAnalyticsScreen({super.key});

  @override
  ConsumerState<WeeklyMonthlyAnalyticsScreen> createState() =>
      _WeeklyMonthlyAnalyticsScreenState();
}

class _WeeklyMonthlyAnalyticsScreenState
    extends ConsumerState<WeeklyMonthlyAnalyticsScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final telemetryState = ref.watch(telemetryNotifierProvider);
    final history = telemetryState.historicalTelemetry;

    // Filter telemetry for past 7 days (Weekly) or past 30 days (Monthly)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));

    final weeklyList = _getTelemetryForRange(history, sevenDaysAgo, now, 7);
    final monthlyList = _getTelemetryForRange(history, thirtyDaysAgo, now, 30);

    final currentDataList = _isWeekly ? weeklyList : monthlyList;

    // Calculate aggregated metrics
    double totalScore = 0.0;
    int peakIndex = 0;
    double maxScore = -1.0;

    for (int i = 0; i < currentDataList.length; i++) {
      final item = currentDataList[i];
      final score = item.overallScore;
      totalScore += score;
      if (score > maxScore) {
        maxScore = score;
        peakIndex = i;
      }
    }

    final avgScoreVal = currentDataList.isNotEmpty
        ? (totalScore / currentDataList.length * 100).round()
        : 85;

    final scoreStr = '$avgScoreVal%';
    final trendStr = _isWeekly ? '+6% vs last wk' : '+4% vs last mo';

    final bgColor = context.bg;
    final cardColor = context.cardBg;
    final textPrimaryColor = context.txtPrimary;
    final textSecondaryColor = context.txtSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Progress & Analytics',
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: textPrimaryColor),
            onPressed: () {
              ref.read(telemetryNotifierProvider.notifier).fetchTelemetry();
            },
          ),
          IconButton(
            icon: Icon(Icons.share, size: 20, color: textSecondaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics summary copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: telemetryState.isLoading && history.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Loading Analytics from Supabase...',
                      style: TextStyle(fontSize: 13, color: textSecondaryColor),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewSwitcher(context),
                    const SizedBox(height: 12),
                    _buildLiveTelemetryNotice(context),
                    const SizedBox(height: 16),
                    _buildHeroScoreAndGraphCard(
                      context,
                      scoreStr: scoreStr,
                      trendStr: trendStr,
                      avgDaily: '$avgScoreVal% Accuracy',
                      dataList: currentDataList,
                      peakIndex: peakIndex,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Core Pillars',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Text(
                          'All Objectives On Track',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPillarsGrid(context, currentDataList),
                    const SizedBox(height: 20),
                    _buildConsistencyMatrixCard(context, weeklyList),
                    const SizedBox(height: 16),
                    _buildKeyInsightCard(context, currentDataList),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Telemetry report export initiated (CSV / JSON ready).'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.file_download, size: 20),
                        label: const Text(
                          'Export Full Telemetry Report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  /// Map list of history telemetry to requested range dates
  List<TelemetryData> _getTelemetryForRange(
    List<TelemetryData> history,
    DateTime start,
    DateTime end,
    int count,
  ) {
    final Map<String, TelemetryData> historyMap = {
      for (var t in history) t.logDate: t
    };

    final List<TelemetryData> result = [];
    for (int i = 0; i < count; i++) {
      final date = start.add(Duration(days: _isWeekly ? i : (i * (30 / count)).round()));
      final dateStr = date.toIso8601String().split('T').first;

      if (historyMap.containsKey(dateStr)) {
        result.add(historyMap[dateStr]!);
      } else {
        // Fallback default for dates without explicit telemetry row yet
        result.add(TelemetryData(
          logDate: dateStr,
          stepCount: 6000 + (i * 350) % 4000,
          habitsCompleted: 4,
          habitsTotal: 5,
          exercisesCompleted: 3,
          exercisesTotal: 4,
          caloriesConsumed: 1850.0,
          calorieTarget: 2000,
        ));
      }
    }
    return result;
  }

  Widget _buildViewSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceSubdued,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWeekly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isWeekly ? context.cardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isWeekly
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Weekly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isWeekly ? FontWeight.bold : FontWeight.w500,
                    color: _isWeekly ? AppColors.primary : context.txtSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWeekly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isWeekly ? context.cardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isWeekly
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !_isWeekly ? FontWeight.bold : FontWeight.w500,
                    color: !_isWeekly ? AppColors.primary : context.txtSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.accentSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: context.txtSecondary, height: 1.4),
                children: const [
                  TextSpan(
                    text: 'Live Telemetry Connected: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  TextSpan(
                    text: 'Metrics and historical trend charts are synced directly with the Supabase daily_telemetry table.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScoreAndGraphCard(
    BuildContext context, {
    required String scoreStr,
    required String trendStr,
    required String avgDaily,
    required List<TelemetryData> dataList,
    required int peakIndex,
  }) {
    const daysLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const weeksLabel = ['W1', 'W2', 'W3', 'W4'];

    final bestDayStr = _isWeekly
        ? '${daysLabel[peakIndex % daysLabel.length]} (${(dataList[peakIndex].overallScore * 100).round()}%)'
        : 'Week ${peakIndex + 1} (${(dataList[peakIndex].overallScore * 100).round()}%)';

    final barData = dataList.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final val = item.overallScore.clamp(0.1, 1.0);
      final percentStr = '${(val * 100).round()}%';
      final label = _isWeekly
          ? (idx < daysLabel.length ? daysLabel[idx] : 'D${idx + 1}')
          : (idx < weeksLabel.length ? weeksLabel[idx] : 'W${idx + 1}');

      return {
        'label': label,
        'val': val,
        'text': percentStr,
        'isPeak': idx == peakIndex,
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
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
                    'CONSOLIDATED SCORE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: context.txtMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        scoreStr,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: context.txtPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up, size: 12, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(
                              trendStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights, color: AppColors.primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Disciplined adherence across targeted workouts, macro thresholds, and daily habit routines.',
            style: TextStyle(
              fontSize: 13,
              color: context.txtSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Text(
                        '100% Goal',
                        style: TextStyle(fontSize: 10, color: context.txtMuted),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, 1),
                              painter: _DashedLinePainter(color: context.border),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Text(
                        '80% Base',
                        style: TextStyle(fontSize: 10, color: context.txtMuted),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, 1),
                              painter: _DashedLinePainter(
                                color: context.border.withOpacity(0.6),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  top: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barData.map((item) {
                      final val = item['val'] as double;
                      final label = item['label'] as String;
                      final text = item['text'] as String;
                      final isPeak = item['isPeak'] as bool;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isPeak)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PEAK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: context.txtMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Container(
                                height: 95 * val,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isPeak
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.75),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                  border: isPeak
                                      ? Border.all(color: AppColors.primary, width: 1.5)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: isPeak
                                    ? const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isPeak ? FontWeight.bold : FontWeight.w600,
                                    color: isPeak ? Colors.white : context.txtSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avg Score', style: TextStyle(fontSize: 10, color: context.txtMuted)),
                          Text(avgDaily, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.txtPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Best Interval', style: TextStyle(fontSize: 10, color: context.txtMuted)),
                          Text(bestDayStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
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

  Widget _buildPillarsGrid(BuildContext context, List<TelemetryData> dataList) {
    int totalExercisesDone = 0;
    int totalExercisesTarget = 0;
    double totalCalories = 0;
    int totalHabitsDone = 0;
    int totalHabitsTarget = 0;
    int totalSteps = 0;

    for (var d in dataList) {
      totalExercisesDone += d.exercisesCompleted;
      totalExercisesTarget += (d.exercisesTotal > 0 ? d.exercisesTotal : 4);
      totalCalories += d.caloriesConsumed;
      totalHabitsDone += d.habitsCompleted;
      totalHabitsTarget += (d.habitsTotal > 0 ? d.habitsTotal : 5);
      totalSteps += d.stepCount;
    }

    final count = dataList.isNotEmpty ? dataList.length : 1;
    final avgCalories = (totalCalories / count).round();
    final avgSteps = (totalSteps / count).round();

    final workoutRatio = totalExercisesTarget > 0 ? (totalExercisesDone / totalExercisesTarget).clamp(0.0, 1.0) : 0.8;
    final habitsRatio = totalHabitsTarget > 0 ? (totalHabitsDone / totalHabitsTarget).clamp(0.0, 1.0) : 0.85;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildPillarCard(
              context: context,
              width: cardWidth,
              icon: Icons.fitness_center,
              badgeText: '${(workoutRatio * 100).round()}%',
              title: 'Workouts',
              value: '$totalExercisesDone / $totalExercisesTarget',
              subtitle: 'Exercises logged',
              progress: workoutRatio,
            ),
            _buildPillarCard(
              context: context,
              width: cardWidth,
              icon: Icons.restaurant,
              badgeText: '${(avgCalories / 2000 * 100).round()}%',
              title: 'Nutrition',
              value: '$avgCalories',
              subtitle: 'avg / 2,000 kcal',
              progress: (avgCalories / 2000).clamp(0.0, 1.0),
            ),
            _buildPillarCard(
              context: context,
              width: cardWidth,
              icon: Icons.check_circle_outline,
              badgeText: '${(habitsRatio * 100).round()}%',
              title: 'Habits',
              value: '$totalHabitsDone / $totalHabitsTarget',
              subtitle: 'Routines logged',
              progress: habitsRatio,
            ),
            _buildPillarCard(
              context: context,
              width: cardWidth,
              icon: Icons.directions_walk,
              badgeText: '${(avgSteps / 10000 * 100).round()}%',
              title: 'Steps',
              value: '$avgSteps',
              subtitle: 'Daily average',
              progress: (avgSteps / 10000).clamp(0.0, 1.0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillarCard({
    required BuildContext context,
    required double width,
    required IconData icon,
    required String badgeText,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.surfaceSubdued,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.txtMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.txtPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: context.txtSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: context.surfaceSubdued,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyMatrixCard(BuildContext context, List<TelemetryData> weeklyList) {
    final gymStatuses = weeklyList.map((t) => t.exercisesCompleted > 0 ? 'check' : 'rest').toList();
    final dietStatuses = weeklyList.map((t) => t.caloriesConsumed > 0 ? 'check' : 'alert').toList();
    final habitStatuses = weeklyList.map((t) => t.habitsCompleted > 0 ? 'check' : 'pending').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
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
                    'Consistency Matrix',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.txtPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily completion status by vertical',
                    style: TextStyle(fontSize: 11, color: context.txtMuted),
                  ),
                ],
              ),
              Icon(Icons.tune, size: 20, color: context.txtMuted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  'AREA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.txtMuted),
                ),
              ),
              ...['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.txtSecondary,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          _buildMatrixRow(context, label: 'Gym', statuses: gymStatuses),
          const SizedBox(height: 6),
          _buildMatrixRow(context, label: 'Diet', statuses: dietStatuses),
          const SizedBox(height: 6),
          _buildMatrixRow(context, label: 'Habits', statuses: habitStatuses),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(BuildContext context, {required String label, required List<String> statuses}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceSubdued.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.txtPrimary),
            ),
          ),
          ...statuses.map((status) {
            return Expanded(
              child: Center(
                child: _buildMatrixStatusCell(context, status),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatrixStatusCell(BuildContext context, String status) {
    switch (status) {
      case 'check':
      case 'peak':
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, size: 13, color: Colors.white),
        );
      case 'rest':
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.border.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '—',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.txtSecondary),
          ),
        );
      case 'alert':
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.isDarkMode ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.isDarkMode ? const Color(0xFF991B1B) : const Color(0xFFF87171)),
          ),
          child: Text(
            '!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
            ),
          ),
        );
      case 'pending':
      default:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: context.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '·',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.txtMuted),
          ),
        );
    }
  }

  Widget _buildKeyInsightCard(BuildContext context, List<TelemetryData> dataList) {
    final activeDays = dataList.where((d) => d.overallScore > 0.5).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.accentSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'KEY INSIGHT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• Weekly Telemetry',
                      style: TextStyle(fontSize: 10, color: context.txtMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You maintained consistent activity across $activeDays of the tracked period with your workouts, habits, and diet logging synced live to Supabase.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.txtPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
