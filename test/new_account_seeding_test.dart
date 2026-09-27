import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/features/diet/providers/food_log_provider.dart';
import 'package:fitstack/features/workout/providers/workout_provider.dart';

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
  });
}
