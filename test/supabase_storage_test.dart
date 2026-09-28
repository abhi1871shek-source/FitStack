import 'package:flutter_test/flutter_test.dart';
import 'package:fitstack/core/services/storage_service.dart';
import 'package:fitstack/features/diet/models/food_item.dart';
import 'package:fitstack/features/workout/models/exercise.dart';

void main() {
  group('Supabase Storage & Custom Models Integration Tests', () {
    test('StorageService.bucketName is user-uploads', () {
      expect(StorageService.bucketName, 'user-uploads');
    });

    test('Custom FoodItem retains custom image_asset URL', () {
      const customUrl = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co/storage/v1/object/public/user-uploads/test_user/foods/f_custom_1.jpg';
      final food = FoodItem(
        id: 'f_custom_1',
        name: 'Avocado Toast with Egg',
        cuisine: 'American',
        baseServing: '1 serving (150g)',
        baseServingGrams: 150,
        calories: 320,
        proteinGrams: 14,
        carbsGrams: 28,
        fatGrams: 18,
        fiberGrams: 6,
        category: 'Meals',
        imageAsset: customUrl,
      );

      expect(food.imageAsset, customUrl);
      final map = food.toMap(userId: 'test_user');
      expect(map['image_asset'], customUrl);
      expect(map['user_id'], 'test_user');

      final restored = FoodItem.fromMap(map);
      expect(restored.imageAsset, customUrl);
    });

    test('Custom Exercise retains custom image_url URL', () {
      const customUrl = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co/storage/v1/object/public/user-uploads/test_user/exercises/ex_custom_1.jpg';
      final ex = Exercise(
        id: 'ex_custom_1',
        name: 'Resistance Band Rows',
        muscleGroup: 'Back',
        defaultSets: 4,
        defaultReps: 12,
        defaultWeightKg: 15.0,
        imageUrl: customUrl,
      );

      expect(ex.imageUrl, customUrl);
      final map = ex.toMap();
      map['user_id'] = 'test_user';
      expect(map['image_url'], customUrl);

      final restored = Exercise.fromMap(map);
      expect(restored.imageUrl, customUrl);
    });
  });
}
