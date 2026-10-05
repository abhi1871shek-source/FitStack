import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitstack/core/config/supabase_config.dart';
import 'package:fitstack/core/services/storage_service.dart';
import 'package:fitstack/features/diet/models/food_item.dart';
import 'package:fitstack/features/workout/models/exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  });

  test('Live Verification: Upload custom food & exercise photos and check DB rows', () async {
    final client = Supabase.instance.client;

    // 1. Sign in or Sign up test user
    String userId;
    const testEmail = 'photo_test_user@fitstack.com';
    const testPassword = 'Password123!';

    try {
      final res = await client.auth.signInWithPassword(email: testEmail, password: testPassword);
      userId = res.user!.id;
    } catch (_) {
      final res = await client.auth.signUp(email: testEmail, password: testPassword);
      userId = res.user!.id;
    }
    print('[TEST] Logged in user ID: $userId');

    // 2. Read test image bytes from test_salad.png
    final sampleImageFile = File('test_salad.png');
    expect(sampleImageFile.existsSync(), true, reason: 'test_salad.png must exist');
    final imageBytes = await sampleImageFile.readAsBytes();
    print('[TEST] Loaded test_salad.png bytes (${imageBytes.length} bytes)');

    // 3. Test Custom Food Creation & Upload
    final foodCustomId = 'f_custom_${DateTime.now().millisecondsSinceEpoch}';
    final uploadedFoodUrl = await StorageService.uploadImage(
      imageBytes: imageBytes,
      userId: userId,
      subFolder: 'foods',
      itemId: foodCustomId,
    );
    print('[TEST] Uploaded Food Image URL: $uploadedFoodUrl');
    expect(uploadedFoodUrl, isNotNull);
    expect(uploadedFoodUrl!.startsWith('http'), true, reason: 'Should return a real http public URL');

    // Verify uploaded food URL is publicly accessible
    final foodImgHttpRes = await http.get(Uri.parse(uploadedFoodUrl!));
    print('[TEST] Food Image HTTP Status: ${foodImgHttpRes.statusCode}');
    expect(foodImgHttpRes.statusCode, 200, reason: 'Uploaded food image URL must be publicly loadable');

    final testFood = FoodItem(
      id: foodCustomId,
      name: 'Verification Custom Salad',
      cuisine: 'Mediterranean',
      baseServing: '1 bowl (200g)',
      baseServingGrams: 200.0,
      calories: 320.0,
      proteinGrams: 12.0,
      carbsGrams: 25.0,
      fatGrams: 18.0,
      fiberGrams: 6.0,
      category: 'Vegetables',
      dietaryType: 'vegan',
      imageAsset: uploadedFoodUrl,
      photoAuthor: 'User Upload',
    );

    // Save to food_items table
    await client.from('food_items').upsert(testFood.toMap(userId: userId));

    // Fetch back row from DB to confirm image_asset saved correctly
    final savedFoodRow = await client.from('food_items').select().eq('id', foodCustomId).single();
    print('[TEST] Saved Food DB Row: $savedFoodRow');
    expect(savedFoodRow['image_asset'], uploadedFoodUrl);


    // 4. Test Custom Exercise Creation, Upload & Weight Saving
    final exerciseCustomId = 'ex_custom_${DateTime.now().millisecondsSinceEpoch}';
    final uploadedExerciseUrl = await StorageService.uploadImage(
      imageBytes: imageBytes,
      userId: userId,
      subFolder: 'exercises',
      itemId: exerciseCustomId,
    );
    print('[TEST] Uploaded Exercise Image URL: $uploadedExerciseUrl');
    expect(uploadedExerciseUrl, isNotNull);
    expect(uploadedExerciseUrl!.startsWith('http'), true, reason: 'Should return a real http public URL');

    // Verify uploaded exercise URL is publicly accessible
    final exImgHttpRes = await http.get(Uri.parse(uploadedExerciseUrl!));
    print('[TEST] Exercise Image HTTP Status: ${exImgHttpRes.statusCode}');
    expect(exImgHttpRes.statusCode, 200, reason: 'Uploaded exercise image URL must be publicly loadable');

    const testWeightKg = 27.5;
    final testExercise = Exercise(
      id: exerciseCustomId,
      name: 'Verification Custom Press',
      muscleGroup: 'Chest',
      defaultSets: 4,
      defaultReps: 12,
      defaultWeightKg: testWeightKg,
      imageUrl: uploadedExerciseUrl,
    );

    final exMap = testExercise.toMap();
    exMap['user_id'] = userId;
    await client.from('exercises').upsert(exMap);

    // Fetch back row from DB to confirm image_url and weight saved correctly
    final savedExRow = await client.from('exercises').select().eq('id', exerciseCustomId).single();
    print('[TEST] Saved Exercise DB Row: $savedExRow');
    expect(savedExRow['image_url'], uploadedExerciseUrl);
    expect((savedExRow['default_weight_kg'] as num).toDouble(), testWeightKg);

    // Also log this exercise to workout_logs
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final logItem = WorkoutLogItem(
      id: '',
      exerciseId: exerciseCustomId,
      name: testExercise.name,
      muscleGroup: testExercise.muscleGroup,
      sets: testExercise.defaultSets,
      reps: testExercise.defaultReps,
      weightKg: testExercise.defaultWeightKg,
      imageUrl: uploadedExerciseUrl,
    );
    final logMap = logItem.toMap(userId: userId, workoutDate: todayStr);
    final insertedLog = await client.from('workout_logs').insert(logMap).select().single();
    print('[TEST] Inserted Workout Log DB Row: $insertedLog');
    expect(insertedLog['image_url'], uploadedExerciseUrl);
    expect((insertedLog['weight_kg'] as num).toDouble(), testWeightKg);

    print('[TEST] LIVE VERIFICATION SUCCESSFUL!');
  });
}
