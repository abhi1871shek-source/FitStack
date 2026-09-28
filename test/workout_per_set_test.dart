import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/features/workout/models/exercise.dart';

void main() {
  group('Per-Set Workout Model & Summary Tests', () {
    test('ExerciseSet serialization and deserialization', () {
      final set1 = ExerciseSet(setNumber: 1, reps: 10, weightKg: 40.0);
      final map = set1.toMap();

      expect(map['set'], equals(1));
      expect(map['reps'], equals(10));
      expect(map['weight_kg'], equals(40.0));

      final parsed = ExerciseSet.fromMap(map, 1);
      expect(parsed.setNumber, equals(1));
      expect(parsed.reps, equals(10));
      expect(parsed.weightKg, equals(40.0));
    });

    test('WorkoutLogItem with uniform sets summary', () {
      final item = WorkoutLogItem(
        id: 'w_1',
        exerciseId: 'ex_1',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        sets: 3,
        reps: 10,
        weightKg: 40.0,
        setDetails: const [
          ExerciseSet(setNumber: 1, reps: 10, weightKg: 40.0),
          ExerciseSet(setNumber: 2, reps: 10, weightKg: 40.0),
          ExerciseSet(setNumber: 3, reps: 10, weightKg: 40.0),
        ],
      );

      expect(item.repsAndWeightSummary, equals('3 sets × 10 reps • 40 kg'));
    });

    test('WorkoutLogItem with varying sets summary', () {
      final item = WorkoutLogItem(
        id: 'w_2',
        exerciseId: 'ex_1',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        sets: 3,
        reps: 10,
        weightKg: 40.0,
        setDetails: const [
          ExerciseSet(setNumber: 1, reps: 10, weightKg: 40.0),
          ExerciseSet(setNumber: 2, reps: 8, weightKg: 30.0),
          ExerciseSet(setNumber: 3, reps: 6, weightKg: 25.0),
        ],
      );

      expect(item.repsAndWeightSummary, equals('3 sets × 6–10 reps • 25–40 kg'));
    });

    test('WorkoutLogItem toMap includes set_details JSON array', () {
      final item = WorkoutLogItem(
        id: 'w_3',
        exerciseId: 'ex_2',
        name: 'Incline Dumbbell Press',
        muscleGroup: 'Chest',
        sets: 2,
        reps: 12,
        weightKg: 20.0,
        setDetails: const [
          ExerciseSet(setNumber: 1, reps: 12, weightKg: 20.0),
          ExerciseSet(setNumber: 2, reps: 10, weightKg: 22.5),
        ],
      );

      final map = item.toMap(userId: 'u_123');
      expect(map['sets'], equals(2));
      expect(map['set_details'], isA<List>());
      final setDetailsList = map['set_details'] as List;
      expect(setDetailsList.length, equals(2));
      expect(setDetailsList[0]['reps'], equals(12));
      expect(setDetailsList[0]['weight_kg'], equals(20.0));
      expect(setDetailsList[1]['reps'], equals(10));
      expect(setDetailsList[1]['weight_kg'], equals(22.5));
    });

    test('WorkoutLogItem.fromMap parses set_details correctly', () {
      final rawMap = {
        'id': 'w_4',
        'exercise_id': 'ex_6',
        'name': 'Lat Pulldown',
        'muscle_group': 'Back',
        'sets': 3,
        'reps': 10,
        'weight_kg': 35.0,
        'set_details': [
          {'set': 1, 'reps': 10, 'weight_kg': 35.0},
          {'set': 2, 'reps': 8, 'weight_kg': 40.0},
          {'set': 3, 'reps': 6, 'weight_kg': 45.0},
        ],
        'is_completed': false,
      };

      final item = WorkoutLogItem.fromMap(rawMap);
      expect(item.setDetails.length, equals(3));
      expect(item.setDetails[0].reps, equals(10));
      expect(item.setDetails[0].weightKg, equals(35.0));
      expect(item.setDetails[1].reps, equals(8));
      expect(item.setDetails[1].weightKg, equals(40.0));
      expect(item.setDetails[2].reps, equals(6));
      expect(item.setDetails[2].weightKg, equals(45.0));
    });
  });
}
