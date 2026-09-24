class FoodItem {
  final String id;
  final String name;
  final String cuisine; // 'Kerala', 'North Indian', 'South Indian', 'American', 'Mediterranean', 'Chinese'
  final String baseServing; // e.g. '100g', '1 piece (50g)', '1 bowl (150g)'
  final double baseServingGrams; // e.g. 100.0, 50.0, 150.0
  final double calories; // kcal per base serving
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
  final String category; // 'Protein', 'Carbs', 'Healthy Fats', 'Vegetables', 'Fruits', 'Meals', 'Snacks'
  final String dietaryType;
  final String imageAsset;
  final String photoAuthor;
  final String photoLicense;

  const FoodItem({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.baseServing,
    required this.baseServingGrams,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.category,
    this.dietaryType = 'non-vegetarian',
    this.imageAsset = '',
    this.photoAuthor = 'Wikimedia Commons',
    this.photoLicense = 'CC BY-SA 4.0',
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      cuisine: map['cuisine'] as String? ?? 'General',
      baseServing: map['base_serving'] as String? ?? '100g',
      baseServingGrams: (map['base_serving_grams'] as num?)?.toDouble() ?? 100.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      proteinGrams: (map['protein_grams'] as num?)?.toDouble() ?? 0.0,
      carbsGrams: (map['carbs_grams'] as num?)?.toDouble() ?? 0.0,
      fatGrams: (map['fat_grams'] as num?)?.toDouble() ?? 0.0,
      fiberGrams: (map['fiber_grams'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Meals',
      dietaryType: map['dietary_type'] as String? ?? 'non-vegetarian',
      imageAsset: map['image_asset'] as String? ?? '',
      photoAuthor: map['photo_author'] as String? ?? 'Wikimedia Commons',
      photoLicense: map['photo_license'] as String? ?? 'CC BY-SA 4.0',
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'cuisine': cuisine,
      'base_serving': baseServing,
      'base_serving_grams': baseServingGrams,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'fiber_grams': fiberGrams,
      'category': category,
      'dietary_type': dietaryType,
      'image_asset': imageAsset,
      'photo_author': photoAuthor,
      'photo_license': photoLicense,
    };
    return map;
  }
}

class LoggedFoodItem {
  final String id;
  final String foodId;
  final String name;
  final String cuisine;
  final String mealSection; // 'Breakfast', 'Lunch', 'Snacks', 'Dinner'
  final double quantityGrams; // quantity entered by user (e.g. 150.0g)
  final String unit; // 'g' or 'piece'
  final double calories; // calculated proportional calories
  final double proteinGrams; // calculated proportional protein
  final double carbsGrams; // calculated proportional carbs
  final double fatGrams; // calculated proportional fat
  final double fiberGrams; // calculated proportional fiber
  final String loggedTime; // e.g. '8:30 AM'
  final String imageAsset;
  final String photoAuthor;
  final String photoLicense;

  const LoggedFoodItem({
    required this.id,
    required this.foodId,
    required this.name,
    required this.cuisine,
    required this.mealSection,
    required this.quantityGrams,
    this.unit = 'g',
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.loggedTime,
    this.imageAsset = '',
    this.photoAuthor = 'Wikimedia Commons',
    this.photoLicense = 'CC BY-SA 4.0',
  });

  /// Factory helper that performs quantity-based proportional scaling math
  factory LoggedFoodItem.fromFoodItem({
    required String id,
    required FoodItem food,
    required String mealSection,
    required double quantityGrams,
    String unit = 'g',
    required String loggedTime,
  }) {
    final scaleFactor = food.baseServingGrams > 0 ? quantityGrams / food.baseServingGrams : 1.0;

    return LoggedFoodItem(
      id: id,
      foodId: food.id,
      name: food.name,
      cuisine: food.cuisine,
      mealSection: mealSection,
      quantityGrams: quantityGrams,
      unit: unit,
      calories: (food.calories * scaleFactor),
      proteinGrams: (food.proteinGrams * scaleFactor),
      carbsGrams: (food.carbsGrams * scaleFactor),
      fatGrams: (food.fatGrams * scaleFactor),
      fiberGrams: (food.fiberGrams * scaleFactor),
      loggedTime: loggedTime,
      imageAsset: food.imageAsset.isNotEmpty ? food.imageAsset : 'assets/images/food/${food.id}.jpg',
      photoAuthor: food.photoAuthor,
      photoLicense: food.photoLicense,
    );
  }

  factory LoggedFoodItem.fromMap(Map<String, dynamic> map) {
    return LoggedFoodItem(
      id: map['id']?.toString() ?? '',
      foodId: map['food_id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      cuisine: map['cuisine'] as String? ?? 'General',
      mealSection: map['meal_section'] as String? ?? 'Lunch',
      quantityGrams: (map['quantity_grams'] as num?)?.toDouble() ?? 100.0,
      unit: map['unit'] as String? ?? 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      proteinGrams: (map['protein_grams'] as num?)?.toDouble() ?? 0.0,
      carbsGrams: (map['carbs_grams'] as num?)?.toDouble() ?? 0.0,
      fatGrams: (map['fat_grams'] as num?)?.toDouble() ?? 0.0,
      fiberGrams: (map['fiber_grams'] as num?)?.toDouble() ?? 0.0,
      loggedTime: map['logged_time'] as String? ?? '12:00 PM',
      imageAsset: map['image_asset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap({required String userId, String? logDate}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'food_id': foodId,
      'name': name,
      'cuisine': cuisine,
      'meal_section': mealSection,
      'quantity_grams': quantityGrams,
      'unit': unit,
      'calories': calories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'fiber_grams': fiberGrams,
      'logged_time': loggedTime,
      'log_date': logDate ?? DateTime.now().toIso8601String().split('T').first,
      'image_asset': imageAsset,
    };
    if (id.isNotEmpty && !id.startsWith('fl_')) {
      map['id'] = id;
    }
    return map;
  }

  LoggedFoodItem copyWith({
    String? id,
    String? foodId,
    String? name,
    String? cuisine,
    String? mealSection,
    double? quantityGrams,
    String? unit,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? fiberGrams,
    String? loggedTime,
    String? imageAsset,
    String? photoAuthor,
    String? photoLicense,
  }) {
    return LoggedFoodItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      mealSection: mealSection ?? this.mealSection,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      loggedTime: loggedTime ?? this.loggedTime,
      imageAsset: imageAsset ?? this.imageAsset,
      photoAuthor: photoAuthor ?? this.photoAuthor,
      photoLicense: photoLicense ?? this.photoLicense,
    );
  }
}
