/// A single planned meal slot within a weekly diet day.
class PlannedMeal {
  final String foodId;
  final String name;
  final String cuisine;
  final String mealSection; // 'Breakfast' | 'Lunch' | 'Snack' | 'Dinner'
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final String servingDescription; // e.g. '1 bowl (150g)'
  final String imageAsset;

  const PlannedMeal({
    required this.foodId,
    required this.name,
    required this.cuisine,
    required this.mealSection,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.servingDescription,
    this.imageAsset = '',
  });

  PlannedMeal copyWith({
    String? foodId,
    String? name,
    String? cuisine,
    String? mealSection,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    String? servingDescription,
    String? imageAsset,
  }) {
    return PlannedMeal(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      mealSection: mealSection ?? this.mealSection,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      servingDescription: servingDescription ?? this.servingDescription,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  factory PlannedMeal.fromMap(Map<String, dynamic> map) {
    return PlannedMeal(
      foodId: map['food_id']?.toString() ?? '',
      name: map['meal_name'] as String? ?? '',
      cuisine: map['cuisine'] as String? ?? 'General',
      mealSection: map['meal_section'] as String? ?? 'Lunch',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      proteinGrams: (map['protein_grams'] as num?)?.toDouble() ?? 0.0,
      carbsGrams: (map['carbs_grams'] as num?)?.toDouble() ?? 0.0,
      fatGrams: (map['fat_grams'] as num?)?.toDouble() ?? 0.0,
      servingDescription: map['serving_description'] as String? ?? '1 portion',
      imageAsset: map['image_asset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap({required String userId, required String dayName, required String shortName, required int dayIndex, required int dateNum}) {
    return {
      'user_id': userId,
      'day_name': dayName,
      'short_name': shortName,
      'day_index': dayIndex,
      'date_num': dateNum,
      'food_id': foodId,
      'meal_name': name,
      'cuisine': cuisine,
      'meal_section': mealSection,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'serving_description': servingDescription,
      'image_asset': imageAsset,
    };
  }
}

/// One full day in the weekly diet plan.
class PlannedDay {
  final String dayName; // 'Monday', 'Tuesday', ...
  final String shortName; // 'Mon', 'Tue', ...
  final int dateNum;
  final List<PlannedMeal> meals;
  final bool isToday;

  const PlannedDay({
    required this.dayName,
    required this.shortName,
    required this.dateNum,
    required this.meals,
    this.isToday = false,
  });

  double get totalCalories => meals.fold(0, (s, m) => s + m.calories);
  double get totalProtein => meals.fold(0, (s, m) => s + m.proteinGrams);
  double get totalCarbs => meals.fold(0, (s, m) => s + m.carbsGrams);
  double get totalFat => meals.fold(0, (s, m) => s + m.fatGrams);

  PlannedDay copyWith({
    String? dayName,
    String? shortName,
    int? dateNum,
    List<PlannedMeal>? meals,
    bool? isToday,
  }) {
    return PlannedDay(
      dayName: dayName ?? this.dayName,
      shortName: shortName ?? this.shortName,
      dateNum: dateNum ?? this.dateNum,
      meals: meals ?? this.meals,
      isToday: isToday ?? this.isToday,
    );
  }
}
