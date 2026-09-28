import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/features/workout/models/exercise.dart';

void main() {
  test('WorkoutLogItem model initialization test', () {
    const item = WorkoutLogItem(
      id: 'test_1',
      exerciseId: 'ex_1',
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      sets: 3,
      reps: 10,
      weightKg: 40.0,
    );
    expect(item.name, equals('Barbell Bench Press'));
    expect(item.sets, equals(3));
  });
}
