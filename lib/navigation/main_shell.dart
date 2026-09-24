import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/responsive_scaffold.dart';
import '../features/dashboard/screens/home_dashboard_screen.dart';
import '../features/habits/screens/todo_list_screen.dart';
import '../features/progress/screens/progress_today_screen.dart';
import '../features/diet/screens/food_log_screen.dart';
import '../features/workout/screens/workout_today_screen.dart';
import 'providers/navigation_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const List<NavDestinationData> _destinations = [
    NavDestinationData(
      label: 'Home',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    NavDestinationData(
      label: 'To-Do',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
    ),
    NavDestinationData(
      label: 'Progress',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
    ),
    NavDestinationData(
      label: 'Diet',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
    ),
    NavDestinationData(
      label: 'Workout',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
    ),
  ];

  static const List<Widget> _screens = [
    HomeDashboardScreen(),
    TodoListScreen(),
    ProgressTodayScreen(),
    FoodLogScreen(),
    WorkoutTodayScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    return ResponsiveScaffold(
      currentIndex: currentIndex,
      onDestinationSelected: (index) {
        ref.read(navigationProvider.notifier).setTab(index);
      },
      destinations: _destinations,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
    );
  }
}
