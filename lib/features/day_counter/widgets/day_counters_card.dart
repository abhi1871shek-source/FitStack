import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/day_counter.dart';
import '../providers/day_counter_provider.dart';
import '../screens/day_counters_screen.dart';
import 'day_counter_dialog.dart';

class DayCountersCard extends ConsumerWidget {
  const DayCountersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayCountersProvider);
    final cardBg = AppColors.ofCardSurface(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final textPrimary = AppColors.ofTextPrimary(context);
    final textMuted = AppColors.ofTextMuted(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final counters = state.counters;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DayCountersScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
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
            // Card Header: Icon + Title + Manage Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DAY COUNTERS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (counters.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ofSurfaceSubdued(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${counters.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      counters.isNotEmpty ? 'Manage' : '+ Add',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Card Content
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              )
            else if (counters.isEmpty)
              _buildEmptyPrompt(context, textPrimary, textMuted)
            else if (counters.length == 1)
              _buildSingleCounterView(context, counters.first, textPrimary, textMuted, isDark)
            else
              _buildMultiCounterView(context, counters, textPrimary, textMuted, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context, Color textPrimary, Color textMuted) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track milestone days or count down',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Starts at Day 1 or counts down to goal days.',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const DayCounterDialog(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Create', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSingleCounterView(
    BuildContext context,
    DayCounter counter,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final isCountUp = counter.mode == DayCounterMode.countup;
    final accentColor = isCountUp ? AppColors.primary : Colors.orange;
    final isDone = counter.isCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ofSurfaceSubdued(context).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCountUp ? 'COUNT UP' : 'COUNT DOWN',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        counter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  counter.displaySubtitle,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDone ? Colors.green.withOpacity(0.15) : accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDone ? Colors.green.withOpacity(0.4) : accentColor.withOpacity(0.4),
              ),
            ),
            child: Text(
              counter.displayValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDone ? Colors.green : accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiCounterView(
    BuildContext context,
    List<DayCounter> counters,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: counters.map((counter) {
          final isCountUp = counter.mode == DayCounterMode.countup;
          final accentColor = isCountUp ? AppColors.primary : Colors.orange;
          final isDone = counter.isCompleted;

          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
            decoration: BoxDecoration(
              color: AppColors.ofSurfaceSubdued(context).withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.ofBorderSubdued(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCountUp ? Icons.trending_up : Icons.hourglass_bottom,
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        counter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  counter.displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDone ? Colors.green : accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  counter.displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
