import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/day_counter.dart';
import '../providers/day_counter_provider.dart';
import '../widgets/day_counter_dialog.dart';

class DayCountersScreen extends ConsumerWidget {
  const DayCountersScreen({super.key});

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const DayCounterDialog(),
    );
  }

  void _openEditDialog(BuildContext context, DayCounter counter) {
    showDialog(
      context: context,
      builder: (ctx) => DayCounterDialog(counterToEdit: counter),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, DayCounter counter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardBg = AppColors.ofCardSurface(ctx);
        final txtPrimary = AppColors.ofTextPrimary(ctx);
        final txtMuted = AppColors.ofTextMuted(ctx);

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reset Counter?', style: TextStyle(color: txtPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
          content: Text(
            'This will reset "${counter.title}" back to today (Day 1 for countup, or full target days for countdown).',
            style: TextStyle(color: txtMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: txtMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset to Today', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ref.read(dayCountersProvider.notifier).resetCounter(counter.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset "${counter.title}" to today.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, DayCounter counter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cardBg = AppColors.ofCardSurface(ctx);
        final txtPrimary = AppColors.ofTextPrimary(ctx);
        final txtMuted = AppColors.ofTextMuted(ctx);

        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Counter?', style: TextStyle(color: txtPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
          content: Text(
            'Are you sure you want to delete "${counter.title}"? This cannot be undone.',
            style: TextStyle(color: txtMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: txtMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ref.read(dayCountersProvider.notifier).deleteCounter(counter.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${counter.title}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayCountersProvider);
    final bg = AppColors.ofBackground(context);
    final cardBg = AppColors.ofCardSurface(context);
    final txtPrimary = AppColors.ofTextPrimary(context);
    final txtMuted = AppColors.ofTextMuted(context);
    final border = AppColors.ofBorderSubdued(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: txtPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Day Counters',
          style: AppTypography.h2.copyWith(color: txtPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
            tooltip: 'Add New Counter',
            onPressed: () => _openCreateDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.counters.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: state.counters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final counter = state.counters[idx];
                      return _buildCounterCard(context, ref, counter, cardBg, txtPrimary, txtMuted, border, isDark);
                    },
                  ),
      ),
      floatingActionButton: state.counters.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Counter', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final txtPrimary = AppColors.ofTextPrimary(context);
    final txtMuted = AppColors.ofTextMuted(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Day Counters Yet',
              style: AppTypography.h2.copyWith(color: txtPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Track days elapsed on a fitness habit or count down to important milestones and goals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: txtMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openCreateDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Your First Counter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard(
    BuildContext context,
    WidgetRef ref,
    DayCounter counter,
    Color cardBg,
    Color txtPrimary,
    Color txtMuted,
    Color border,
    bool isDark,
  ) {
    final isCountUp = counter.mode == DayCounterMode.countup;
    final accentColor = isCountUp ? AppColors.primary : Colors.orange;
    final isDone = counter.isCompleted;

    double? progress;
    if (!isCountUp && counter.targetDays != null && counter.targetDays! > 0) {
      final elapsed = counter.daysElapsed;
      progress = (elapsed / counter.targetDays!).clamp(0.0, 1.0);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Mode Badge + Actions Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCountUp ? Icons.trending_up : Icons.hourglass_bottom,
                                  size: 12,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCountUp ? 'COUNT UP' : 'COUNT DOWN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isDone) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        counter.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: txtPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card actions: Reset, Edit, Delete
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restart_alt, size: 20),
                      tooltip: 'Reset to Today (Day 1)',
                      color: txtMuted,
                      onPressed: () => _confirmReset(context, ref, counter),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      tooltip: 'Edit Counter',
                      color: txtMuted,
                      onPressed: () => _openEditDialog(context, counter),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 19),
                      tooltip: 'Delete Counter',
                      color: txtMuted,
                      onPressed: () => _confirmDelete(context, ref, counter),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Counter Value Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  counter.displayValue,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDone ? Colors.green : accentColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  counter.displaySubtitle,
                  style: TextStyle(fontSize: 12, color: txtMuted),
                ),
              ],
            ),
          ),

          // Progress Bar for Countdowns
          if (progress != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.ofSurfaceSubdued(context),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Footer: Start Date metadata
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ofSurfaceSubdued(context).withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: txtMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Started: ${_formatDate(counter.startDate)}',
                      style: TextStyle(fontSize: 11, color: txtMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  isCountUp
                      ? 'Local: Day = (today - start) + 1'
                      : 'Target: ${counter.targetDays ?? 0} days',
                  style: TextStyle(fontSize: 10, color: txtMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
