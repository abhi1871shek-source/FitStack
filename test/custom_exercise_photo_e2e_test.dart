import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/core/services/storage_service.dart';
import 'package:fitstack/features/workout/data/exercise_library.dart';
import 'package:fitstack/features/workout/models/exercise.dart';

void main() {
  group('Custom Exercise Photo End-to-End Tests', () {
    test('Storage upload produces non-null valid image URL', () async {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0xFF, 0xD9]);
      final url = await StorageService.uploadImage(
        imageBytes: bytes,
        userId: 'test_user_e2e',
        subFolder: 'exercises',
        itemId: 'ex_custom_test_1',
      );

      expect(url, isNotNull);
      expect(url!.isNotEmpty, true);
      expect(url.startsWith('http') || url.startsWith('data:image'), true);
    });

    test('Custom Exercise retains image_url in model and toMap', () {
      const imgUrl = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co/storage/v1/object/public/user-uploads/test_user/exercises/ex_custom_99.jpg';
      const customEx = Exercise(
        id: 'ex_custom_99',
        name: 'Custom Cable Crossover',
        muscleGroup: 'Chest',
        defaultSets: 3,
        defaultReps: 12,
        defaultWeightKg: 20.0,
        imageUrl: imgUrl,
      );

      expect(customEx.imageUrl, equals(imgUrl));

      final map = customEx.toMap();
      expect(map['image_url'], equals(imgUrl));

      final rehydrated = Exercise.fromMap(map);
      expect(rehydrated.imageUrl, equals(imgUrl));
    });

    test('WorkoutLogItem reads image_url and resolves effectiveImageUrl', () {
      const imgUrl = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/';
      const log = WorkoutLogItem(
        id: 'w_log_custom_1',
        exerciseId: 'ex_custom_99',
        name: 'Custom Cable Crossover',
        muscleGroup: 'Chest',
        sets: 3,
        reps: 12,
        weightKg: 20.0,
        imageUrl: imgUrl,
      );

      expect(log.imageUrl, equals(imgUrl));
      expect(log.effectiveImageUrl, equals(imgUrl));

      final map = log.toMap(userId: 'test_user', workoutDate: '2026-09-30');
      expect(map['image_url'], equals(imgUrl));

      final restoredLog = WorkoutLogItem.fromMap(map);
      expect(restoredLog.imageUrl, equals(imgUrl));
      expect(restoredLog.effectiveImageUrl, equals(imgUrl));
    });

    test('WorkoutLogItem effectiveImageUrl falls back to ExerciseLibrary if log imageUrl is omitted', () {
      const imgUrl = 'data:image/jpeg;base64,test_custom_exercise_image_data';
      const customEx = Exercise(
        id: 'ex_custom_100',
        name: 'Custom Leg Extension',
        muscleGroup: 'Legs',
        defaultSets: 4,
        defaultReps: 15,
        defaultWeightKg: 40.0,
        imageUrl: imgUrl,
      );

      ExerciseLibrary.masterExercises.insert(0, customEx);

      const logWithoutDirectUrl = WorkoutLogItem(
        id: 'w_log_custom_2',
        exerciseId: 'ex_custom_100',
        name: 'Custom Leg Extension',
        muscleGroup: 'Legs',
        sets: 4,
        reps: 15,
        weightKg: 40.0,
        imageUrl: null,
      );

      expect(logWithoutDirectUrl.effectiveImageUrl, equals(imgUrl));
    });
  });
}
