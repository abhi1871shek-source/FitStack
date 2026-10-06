import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image_widget.dart';
import '../../../core/widgets/custom_image_picker_tile.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../data/food_database_data.dart';
import '../models/food_item.dart';
import '../providers/food_log_provider.dart';

class QuickAddFoodSheet extends ConsumerStatefulWidget {
  final FoodItem? initialFood;
  final String? initialMealSection;
  final bool openInCustomMode;

  const QuickAddFoodSheet({
    super.key,
    this.initialFood,
    this.initialMealSection,
    this.openInCustomMode = false,
  });

  @override
  ConsumerState<QuickAddFoodSheet> createState() => _QuickAddFoodSheetState();
}

class _QuickAddFoodSheetState extends ConsumerState<QuickAddFoodSheet> {
  late FoodItem _selectedFood;
  late String _mealSection;
  late double _quantityGrams;
  final TextEditingController _quantityController = TextEditingController();

  // Custom Food Entry Controllers & States
  late bool _isCustomMode;
  Uint8List? _customImageBytes;
  bool _isSaving = false;
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customServingDescController =
      TextEditingController(text: '1 serving (100g)');
  final TextEditingController _customServingGramsController =
      TextEditingController(text: '100');
  final TextEditingController _customCaloriesController =
      TextEditingController(text: '250');
  final TextEditingController _customProteinController =
      TextEditingController(text: '15.0');
  final TextEditingController _customCarbsController =
      TextEditingController(text: '30.0');
  final TextEditingController _customFatController =
      TextEditingController(text: '8.0');
  final TextEditingController _customFiberController =
      TextEditingController(text: '3.0');

  String _customCuisine = 'North Indian';
  String _customDietaryType = 'non-vegetarian';

  final List<String> _mealSections = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];
  final List<String> _cuisines = [
    'Kerala',
    'North Indian',
    'South Indian',
    'American',
    'Mediterranean',
    'Chinese',
    'Arabic',
    'General',
  ];
  final List<String> _dietaryTypes = [
    'vegetarian',
    'vegan',
    'eggetarian',
    'non-vegetarian',
  ];

  @override
  void initState() {
    super.initState();
    _isCustomMode = widget.openInCustomMode;
    _selectedFood = widget.initialFood ?? FoodDatabaseData.masterFoods.first;
    _mealSection = widget.initialMealSection ?? 'Breakfast';
    _quantityGrams = _selectedFood.baseServingGrams;
    _quantityController.text = _quantityGrams.toStringAsFixed(0);

    if (widget.initialFood != null && widget.initialFood!.isCustom) {
      final f = widget.initialFood!;
      _customNameController.text = f.name;
      _customServingDescController.text = f.baseServing;
      _customServingGramsController.text = f.baseServingGrams.toStringAsFixed(0);
      _customCaloriesController.text = f.calories.toStringAsFixed(0);
      _customProteinController.text = f.proteinGrams.toStringAsFixed(1);
      _customCarbsController.text = f.carbsGrams.toStringAsFixed(1);
      _customFatController.text = f.fatGrams.toStringAsFixed(1);
      _customFiberController.text = f.fiberGrams.toStringAsFixed(1);
      if (_cuisines.contains(f.cuisine)) _customCuisine = f.cuisine;
      if (_dietaryTypes.contains(f.dietaryType)) _customDietaryType = f.dietaryType;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      FoodDatabaseData.loadCustomFoods(userId).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  final TextEditingController _librarySearchController = TextEditingController();
  String _librarySearchQuery = '';

  @override
  void dispose() {
    _librarySearchController.dispose();
    _quantityController.dispose();
    _customNameController.dispose();
    _customServingDescController.dispose();
    _customServingGramsController.dispose();
    _customCaloriesController.dispose();
    _customProteinController.dispose();
    _customCarbsController.dispose();
    _customFatController.dispose();
    _customFiberController.dispose();
    super.dispose();
  }

  void _updateQuantity(double newQty) {
    if (newQty <= 0) return;
    setState(() {
      _quantityGrams = newQty;
      _quantityController.text = _quantityGrams.toStringAsFixed(0);
    });
  }

  Future<void> _saveAndLogCustomFood() async {
    final name = _customNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom food name.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final calories = double.tryParse(_customCaloriesController.text.trim()) ?? 250.0;
    final protein = double.tryParse(_customProteinController.text.trim()) ?? 15.0;
    final carbs = double.tryParse(_customCarbsController.text.trim()) ?? 30.0;
    final fat = double.tryParse(_customFatController.text.trim()) ?? 8.0;
    final fiber = double.tryParse(_customFiberController.text.trim()) ?? 3.0;
    final servingGrams = double.tryParse(_customServingGramsController.text.trim()) ?? 100.0;
    final servingDesc = _customServingDescController.text.trim().isEmpty
        ? '1 serving (${servingGrams.toStringAsFixed(0)}g)'
        : _customServingDescController.text.trim();

    final isEditing = widget.initialFood != null && widget.initialFood!.isCustom;
    final customId = isEditing
        ? widget.initialFood!.id
        : 'f_custom_${DateTime.now().millisecondsSinceEpoch}';

    String imageAsset = isEditing ? widget.initialFood!.imageAsset : '';

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (_customImageBytes != null && userId != null) {
      final uploadedUrl = await StorageService.uploadImage(
        imageBytes: _customImageBytes!,
        userId: userId,
        subFolder: 'foods',
        itemId: customId,
      );
      if (uploadedUrl != null) {
        imageAsset = uploadedUrl;
      }
    }

    final customFood = FoodItem(
      id: customId,
      name: name,
      cuisine: _customCuisine,
      baseServing: servingDesc,
      baseServingGrams: servingGrams,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      fiberGrams: fiber,
      category: 'Meals',
      dietaryType: _customDietaryType,
      imageAsset: imageAsset,
    );

    try {
      // 1. Save to Supabase food_items table
      if (userId != null) {
        await client.from('food_items').upsert(customFood.toMap(userId: userId));
      }

      // 2. Add or update master list in memory
      final existingIndex = FoodDatabaseData.masterFoods.indexWhere((f) => f.id == customId);
      if (existingIndex >= 0) {
        FoodDatabaseData.masterFoods[existingIndex] = customFood;
      } else {
        FoodDatabaseData.masterFoods.insert(0, customFood);
      }

      // 3. Log to today's food log
      await ref.read(foodLogProvider.notifier).addLoggedFood(
            food: customFood,
            mealSection: _mealSection,
            quantityGrams: servingGrams,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom food "$name" saved to DB & logged to $_mealSection!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[QuickAddFoodSheet] Error saving custom food to DB: $e');
      if (mounted) {
        // Fallback: log to local provider
        await ref.read(foodLogProvider.notifier).addLoggedFood(
              food: customFood,
              mealSection: _mealSection,
              quantityGrams: servingGrams,
            );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = _selectedFood.baseServingGrams > 0
        ? _quantityGrams / _selectedFood.baseServingGrams
        : 1.0;

    final scaledCalories = (_selectedFood.calories * scaleFactor);
    final scaledProtein = (_selectedFood.proteinGrams * scaleFactor);
    final scaledCarbs = (_selectedFood.carbsGrams * scaleFactor);
    final scaledFat = (_selectedFood.fatGrams * scaleFactor);
    final scaledFiber = (_selectedFood.fiberGrams * scaleFactor);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.ofCardSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header & Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubdued,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCustomMode ? 'Create Custom Food' : 'Quick Add Food',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mode Switcher Segmented Bar: [ Select from Library ] | [ + Custom Food ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubdued,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCustomMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isCustomMode ? AppColors.cardSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_isCustomMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Select from Library',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isCustomMode ? FontWeight.bold : FontWeight.w500,
                            color: !_isCustomMode ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCustomMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isCustomMode ? AppColors.cardSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isCustomMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          '+ Custom Food',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isCustomMode ? FontWeight.bold : FontWeight.w500,
                            color: _isCustomMode ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (!_isCustomMode) ...[
              // Live Search Bar for Food Selection
              TextField(
                controller: _librarySearchController,
                onChanged: (val) {
                  setState(() {
                    _librarySearchQuery = val;
                  });
                },
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search food by name (e.g. Oats, Parotta, Chicken)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                  suffixIcon: _librarySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _librarySearchController.clear();
                            setState(() {
                              _librarySearchQuery = '';
                            });
                          },
                        )
                      : null,
                  fillColor: AppColors.surfaceSubdued,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubdued),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filtered Search Results List (if search active)
              if (_librarySearchQuery.trim().isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final searchMatches = FoodDatabaseData.masterFoods.where((f) {
                      final q = _librarySearchQuery.trim().toLowerCase();
                      return f.name.toLowerCase().contains(q) ||
                          f.cuisine.toLowerCase().contains(q) ||
                          f.category.toLowerCase().contains(q);
                    }).toList();

                    if (searchMatches.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubdued,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_off, size: 18, color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text(
                              'No matching food items found',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: searchMatches.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppColors.borderSubdued),
                        itemBuilder: (ctx, idx) {
                          final food = searchMatches[idx];
                          final isSelected = food.id == _selectedFood.id;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            leading: AppImageWidget(
                              imagePath: food.imageAsset.isNotEmpty
                                  ? food.imageAsset
                                  : 'assets/images/food/${food.id}.jpg',
                              width: 32,
                              height: 32,
                              borderRadius: BorderRadius.circular(6),
                              fallbackIcon: Icons.restaurant,
                            ),
                            title: Text(
                              food.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${food.cuisine} • ${food.baseServing} • ${food.calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, size: 18, color: AppColors.primary)
                                : const Icon(Icons.add_circle_outline, size: 18, color: AppColors.textMuted),
                            onTap: () {
                              setState(() {
                                _selectedFood = food;
                                _quantityGrams = food.baseServingGrams;
                                _quantityController.text = _quantityGrams.toStringAsFixed(0);
                                _librarySearchQuery = '';
                                _librarySearchController.clear();
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Currently Selected Food Item Summary
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final imgPath = _selectedFood.imageAsset.isNotEmpty
                          ? _selectedFood.imageAsset
                          : 'assets/images/food/${_selectedFood.id}.jpg';
                      showImagePreviewDialog(context, imgPath, _selectedFood.name);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AppImageWidget(
                      imagePath: _selectedFood.imageAsset.isNotEmpty
                          ? _selectedFood.imageAsset
                          : 'assets/images/food/${_selectedFood.id}.jpg',
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(10),
                      fallbackIcon: Icons.restaurant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Food Item',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                        ),
                        Text(
                          '${_selectedFood.name} (${_selectedFood.cuisine})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<FoodItem>(
                value: _selectedFood,
                isExpanded: true,
                decoration: InputDecoration(
                  fillColor: AppColors.surfaceSubdued,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubdued),
                  ),
                ),
                items: FoodDatabaseData.masterFoods.map((f) {
                  return DropdownMenuItem<FoodItem>(
                    value: f,
                    child: Text(
                      '${f.name} (${f.cuisine} • ${f.baseServing})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFood = val;
                      _quantityGrams = val.baseServingGrams;
                      _quantityController.text = _quantityGrams.toStringAsFixed(0);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Meal Section Picker Chips
              const Text(
                'Meal Section',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _mealSections.map((section) {
                    final isSelected = _mealSection == section;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(section),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceSubdued,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.borderSubdued,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _mealSection = section;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity Input & Steppers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity (Grams)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  ),
                  Text(
                    'Base: ${_selectedFood.baseServing}',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity((_quantityGrams - 25).clamp(10.0, 2000.0)),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    tooltip: '-25g',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        suffixText: 'g',
                        suffixStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        fillColor: AppColors.surfaceSubdued,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderSubdued),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setState(() {
                            _quantityGrams = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(_quantityGrams + 25),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    tooltip: '+25g',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [50, 100, 150, 200, 250, 300].map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          side: const BorderSide(color: AppColors.borderSubdued),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _updateQuantity(preset.toDouble()),
                        child: Text('${preset}g', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Macro Calculation Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CALCULATED NUTRITION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Scale: ${scaleFactor.toStringAsFixed(2)}x',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${scaledCalories.toStringAsFixed(1)} kcal',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMacroPill('P', '${scaledProtein.toStringAsFixed(1)}g', Colors.blue),
                                const SizedBox(width: 4),
                                _buildMacroPill('C', '${scaledCarbs.toStringAsFixed(1)}g', Colors.orange),
                                const SizedBox(width: 4),
                                _buildMacroPill('F', '${scaledFat.toStringAsFixed(1)}g', Colors.redAccent),
                                const SizedBox(width: 4),
                                _buildMacroPill('Fib', '${scaledFiber.toStringAsFixed(1)}g', Colors.green),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ref.read(foodLogProvider.notifier).addLoggedFood(
                          food: _selectedFood,
                          mealSection: _mealSection,
                          quantityGrams: _quantityGrams,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Log Food to Today\'s Journal',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // TRUE CUSTOM FOOD CREATION PATH
              CustomImagePickerTile(
                selectedImageBytes: _customImageBytes,
                onImagePicked: (bytes) => setState(() => _customImageBytes = bytes),
                label: 'Food Photo (Optional)',
                defaultIcon: Icons.restaurant,
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _customNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Custom Food Name',
                  hintText: 'e.g. Homemade Oats Protein Shake',
                  prefixIcon: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _customCuisine,
                      decoration: const InputDecoration(labelText: 'Cuisine'),
                      items: _cuisines
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _customCuisine = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _customDietaryType,
                      decoration: const InputDecoration(labelText: 'Dietary Type'),
                      items: _dietaryTypes
                          .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _customDietaryType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customServingDescController,
                      decoration: const InputDecoration(
                        labelText: 'Serving Desc',
                        hintText: 'e.g. 1 bowl (200g)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _customServingGramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (Grams)',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCaloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal)',
                        suffixText: 'kcal',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _customProteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCarbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _customFatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _customFiberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fiber (g)',
                        suffixText: 'g',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Meal Section Picker Chips
              const Text(
                'Log to Meal Section',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _mealSections.map((section) {
                    final isSelected = _mealSection == section;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(section),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceSubdued,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (_) => setState(() => _mealSection = section),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveAndLogCustomFood,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add, size: 20),
                  label: Text(
                    _isSaving ? 'Uploading Photo & Saving...' : 'Save Custom Food & Log to Journal',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
