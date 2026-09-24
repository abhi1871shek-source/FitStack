import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_streak_counter.dart';
import '../../../core/widgets/emoji_progress_bar.dart';
import '../models/habit_item.dart';
import '../providers/habits_provider.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  String _selectedCategory = 'All Tasks';
  bool _showCompleted = true;

  final List<String> _categories = ['All Tasks', 'Morning', 'Afternoon', 'Evening'];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _dayNamesShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  String _formatHeaderDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final monthName = _months[dt.month - 1];
    if (isToday) {
      return 'Today, $monthName ${dt.day}';
    } else {
      final dayOfWeek = _dayNamesShort[dt.weekday % 7];
      return '$dayOfWeek, $monthName ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitsProvider);
    final habits = habitsState.habits;
    final notifier = ref.read(habitsProvider.notifier);
    final selectedDate = habitsState.selectedDate;

    final isMobile = MediaQuery.of(context).size.width < 600;

    // Filter by selected category pill
    final filteredHabits = habits.where((h) {
      if (_selectedCategory == 'All Tasks') return true;
      return h.timeOfDay.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final pendingHabits = filteredHabits.where((h) => !h.isCompleted).toList();
    final completedHabits = filteredHabits.where((h) => h.isCompleted).toList();

    // Group pending habits by time of day in fixed sequence: Morning -> Afternoon -> Evening
    final morningPending = pendingHabits.where((h) => h.timeOfDay == 'Morning').toList();
    final afternoonPending = pendingHabits.where((h) => h.timeOfDay == 'Afternoon').toList();
    final eveningPending = pendingHabits.where((h) => h.timeOfDay == 'Evening').toList();

    final totalCompleted = habits.where((h) => h.isCompleted).length;
    final totalCount = habits.length;

    final bgColor = AppColors.ofBackground(context);
    final cardColor = AppColors.ofCardSurface(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final borderColor = AppColors.ofBorderSubdued(context);

    if (habitsState.isLoading && habits.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & 7-Day Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To Do',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatHeaderDate(selectedDate)} • $totalCompleted of $totalCount completed',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
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
                            notifier.setSelectedDate(picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined, size: 20),
                        tooltip: 'Select Date',
                        style: IconButton.styleFrom(
                          backgroundColor: cardColor,
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Habit Completion Emoji Progress Bar (🎯)
                  EmojiProgressBar(
                    progress: totalCount > 0 ? totalCompleted / totalCount : 0.0,
                    emoji: '🎯',
                    height: 8,
                    barColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // 7-Day Compact Strip
                  Builder(
                    builder: (context) {
                      final daysFromSunday = selectedDate.weekday == DateTime.sunday ? 0 : selectedDate.weekday;
                      final weekStart = selectedDate.subtract(Duration(days: daysFromSunday));
                      final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

                      return Row(
                        children: weekDays.map((day) {
                          final isSelectedDay = day.year == selectedDate.year &&
                              day.month == selectedDate.month &&
                              day.day == selectedDate.day;
                          final dayIso = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                          final hasCompletions = habitsState.completedDatesWithHabits.contains(dayIso);
                          final dayLetter = _dayLetters[day.weekday % 7];

                          return _buildDayItem(
                            dayLetter,
                            '${day.day}',
                            isSelectedDay,
                            hasCompletions,
                            onTap: () {
                              notifier.setSelectedDate(day);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Time-of-Day Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: cardColor,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.ofTextSecondary(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : borderColor,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Habit List Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  // Interaction Hint
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
                          isMobile ? 'Swipe right to complete' : 'Click check to complete',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  if (pendingHabits.isEmpty && completedHabits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text(
                        'No habits for this filter! Click + to add one 🎉',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),

                  // Section 1: Morning Pending Habits
                  if (morningPending.isNotEmpty) ...[
                    _buildTimeOfDayHeader('MORNING', Icons.wb_sunny_outlined, morningPending.length),
                    const SizedBox(height: 8),
                    ...morningPending.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: isMobile
                              ? _buildMobileDismissibleCard(context, h, notifier)
                              : _buildHabitCard(context, h, notifier, isMobile: false),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Section 2: Afternoon Pending Habits
                  if (afternoonPending.isNotEmpty) ...[
                    _buildTimeOfDayHeader('AFTERNOON', Icons.wb_twilight, afternoonPending.length),
                    const SizedBox(height: 8),
                    ...afternoonPending.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: isMobile
                              ? _buildMobileDismissibleCard(context, h, notifier)
                              : _buildHabitCard(context, h, notifier, isMobile: false),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Section 3: Evening Pending Habits
                  if (eveningPending.isNotEmpty) ...[
                    _buildTimeOfDayHeader('EVENING', Icons.nights_stay_outlined, eveningPending.length),
                    const SizedBox(height: 8),
                    ...eveningPending.map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: isMobile
                              ? _buildMobileDismissibleCard(context, h, notifier)
                              : _buildHabitCard(context, h, notifier, isMobile: false),
                        )),
                    const SizedBox(height: 12),
                  ],

                  // Section 4: Completed Habits (Dimmed Grey at Bottom)
                  if (completedHabits.isNotEmpty) ...[
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
                                  'COMPLETED (${completedHabits.length})',
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
                      ...completedHabits.map((habit) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: isMobile
                              ? _buildMobileDismissibleCard(context, habit, notifier)
                              : _buildHabitCard(context, habit, notifier, isMobile: false),
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

      // Floating Action Button (+) to add new habit
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showAddHabitDialog(context),
        icon: const Icon(Icons.add, size: 22),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTimeOfDayHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(
    String dayName,
    String dayNum,
    bool isSelected,
    bool isCompleted, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.ofCardSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.ofBorderSubdued(context),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.ofTextMuted(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.ofTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : (isCompleted ? AppColors.primary : AppColors.ofBorderSubdued(context)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Swipe Dismissible Wrapper
  Widget _buildMobileDismissibleCard(
    BuildContext context,
    HabitItem habit,
    HabitsNotifier notifier,
  ) {
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          notifier.toggleHabit(habit.id, true);
        } else if (direction == DismissDirection.endToStart) {
          notifier.toggleHabit(habit.id, false);
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
              'Mark Complete',
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
      child: _buildHabitCard(context, habit, notifier, isMobile: true),
    );
  }

  // Habit Card Core
  Widget _buildHabitCard(
    BuildContext context,
    HabitItem habit,
    HabitsNotifier notifier, {
    required bool isMobile,
  }) {
    return InkWell(
      onLongPress: () => _showEditDeleteOptions(context, habit),
      onSecondaryTap: () => _showEditDeleteOptions(context, habit),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: habit.isCompleted ? AppColors.ofSurfaceSubdued(context).withOpacity(0.7) : AppColors.ofCardSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: habit.isCompleted ? AppColors.ofBorderSubdued(context).withOpacity(0.5) : AppColors.ofBorderSubdued(context),
          ),
          boxShadow: habit.isCompleted
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
            if (!habit.isCompleted)
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
              onTap: () => notifier.toggleHabit(habit.id),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: habit.isCompleted ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: habit.isCompleted ? AppColors.primary : AppColors.borderSubdued,
                    width: 1.8,
                  ),
                ),
                child: habit.isCompleted
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: habit.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                      decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 9)),
                            AnimatedStreakCounter(
                              count: habit.streakDays,
                              suffix: 'd',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (habit.reminderMinutesBefore != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                size: 10,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${habit.reminderMinutesBefore}m before',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Desktop Explicit Action Buttons
            if (!isMobile) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                onPressed: () => _showEditHabitDialog(context, habit),
                tooltip: 'Edit Habit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                onPressed: () => notifier.deleteHabit(habit.id),
                tooltip: 'Delete Habit',
              ),
            ] else ...[
              const Icon(Icons.drag_indicator, size: 18, color: AppColors.borderSubdued),
            ],
          ],
        ),
      ),
    );
  }

  // Context Menu for Edit / Delete Options
  void _showEditDeleteOptions(BuildContext context, HabitItem habit) {
    final notifier = ref.read(habitsProvider.notifier);
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
                  habit.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Edit Habit'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditHabitDialog(context, habit);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                  title: Text(habit.isCompleted ? 'Mark as Pending' : 'Mark as Completed'),
                  onTap: () {
                    Navigator.pop(ctx);
                    notifier.toggleHabit(habit.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  title: const Text('Delete Habit', style: TextStyle(color: Color(0xFFEF4444))),
                  onTap: () {
                    Navigator.pop(ctx);
                    notifier.deleteHabit(habit.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  // Dialog to Add a New Habit
  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String timeOfDay = 'Morning';
    String category = 'Routine';
    TimeOfDay? selectedTime = _defaultTimeForSection('Morning');
    int? reminderMinutes = 10; // Default 10 minutes before

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.ofCardSurface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_task, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Add New Habit', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      decoration: const InputDecoration(labelText: 'Time of Day Section'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: ['Routine', 'Workout', 'Nutrition', 'Habits']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                      decoration: const InputDecoration(labelText: 'Type Tag'),
                    ),
                    const SizedBox(height: 12),
                    // Interactive Time Picker Tile
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
                                color: AppColors.ofCardSurface(context),
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
                        labelText: 'Target / Subtitle (optional)',
                        hintText: 'e.g. 3,000 steps',
                      ),
                    ),
                  ],
                ),
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
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      final formattedTime = selectedTime?.format(context);
                      ref.read(habitsProvider.notifier).addHabit(
                            title: title,
                            timeOfDay: timeOfDay,
                            category: category,
                            time: formattedTime,
                            subtitle: subtitleController.text.trim().isEmpty ? null : subtitleController.text.trim(),
                            reminderMinutesBefore: reminderMinutes,
                            scheduledHour: selectedTime?.hour,
                            scheduledMinute: selectedTime?.minute,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog to Edit an Existing Habit
  void _showEditHabitDialog(BuildContext context, HabitItem habit) {
    final titleController = TextEditingController(text: habit.title);
    final subtitleController = TextEditingController(text: habit.subtitle ?? '');
    String timeOfDay = habit.timeOfDay;
    String category = habit.category;
    TimeOfDay? selectedTime = habit.scheduledHour != null && habit.scheduledMinute != null
        ? TimeOfDay(hour: habit.scheduledHour!, minute: habit.scheduledMinute!)
        : _defaultTimeForSection(habit.timeOfDay);
    int? reminderMinutes = habit.reminderMinutesBefore;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.ofCardSurface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Edit Habit', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Habit Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Morning', 'Afternoon', 'Evening'].contains(timeOfDay) ? timeOfDay : 'Morning',
                      items: ['Morning', 'Afternoon', 'Evening']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            timeOfDay = val;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Time of Day Section'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Routine', 'Workout', 'Nutrition', 'Habits'].contains(category) ? category : 'Routine',
                      items: ['Routine', 'Workout', 'Nutrition', 'Habits']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                      decoration: const InputDecoration(labelText: 'Type Tag'),
                    ),
                    const SizedBox(height: 12),
                    // Interactive Time Picker Tile
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
                                color: AppColors.ofCardSurface(context),
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
                      decoration: const InputDecoration(labelText: 'Target / Subtitle (optional)'),
                    ),
                  ],
                ),
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
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      final formattedTime = selectedTime?.format(context);
                      ref.read(habitsProvider.notifier).editHabit(
                            habit.id,
                            title: title,
                            timeOfDay: timeOfDay,
                            category: category,
                            time: formattedTime,
                            subtitle: subtitleController.text.trim().isEmpty ? null : subtitleController.text.trim(),
                            reminderMinutesBefore: reminderMinutes,
                            scheduledHour: selectedTime?.hour,
                            scheduledMinute: selectedTime?.minute,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
