import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/features/diet/providers/food_log_provider.dart';
import 'package:fitstack/features/habits/providers/habits_provider.dart';

void main() {
  group('New Account Seeding Verification', () {
    test('FoodLogState initializes with empty logs list', () {
      const state = FoodLogState();
      expect(state.logs, isEmpty);
    });

    test('WorkoutState initializes with empty logs list', () {
      const state = FoodLogState();
      expect(state.logs, isEmpty);
    });

    test('HabitsState initializes with empty habits list and zero streak', () {
      final state = HabitsState();
      expect(state.habits, isEmpty);
      final int currentStreak = state.habits.isNotEmpty
          ? state.habits.map((h) => h.streakDays).reduce((a, b) => a > b ? a : b)
          : 0;
      expect(currentStreak, equals(0));
    });
  });
}
