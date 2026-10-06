import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image_widget.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../data/food_database_data.dart';
import '../models/food_item.dart';
import '../providers/food_log_provider.dart';
import 'quick_add_food_sheet.dart';

class FoodDatabaseScreen extends ConsumerStatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  ConsumerState<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends ConsumerState<FoodDatabaseScreen> {
  String _selectedCuisine = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<FoodItem> _selectedFoods = {};

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      FoodDatabaseData.loadCustomFoods(userId).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  List<String> get _cuisines {
    final set = FoodDatabaseData.masterFoods.map((f) => f.cuisine).toSet().toList()..sort();
    return ['All', 'My Custom', ...set];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQuickAddModal(BuildContext context, FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddFoodSheet(initialFood: food),
    );
  }

  void _openEditCustomFoodModal(BuildContext context, FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddFoodSheet(
        initialFood: food,
        openInCustomMode: true,
      ),
    ).then((_) => setState(() {}));
  }

  void _confirmDeleteCustomFood(BuildContext context, FoodItem food) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.ofCardSurface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Custom Food',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ofTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${food.name}" from your custom food library?',
            style: TextStyle(fontSize: 13, color: AppColors.ofTextSecondary(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FoodDatabaseData.deleteCustomFood(food.id, userId);
                  setState(() {
                    _selectedFoods.remove(food);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Custom food "${food.name}" deleted.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete custom food.')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = FoodDatabaseData.masterFoods.where((food) {
      final matchesCuisine = _selectedCuisine == 'All' ||
          (_selectedCuisine == 'My Custom' ? food.isCustom : food.cuisine == _selectedCuisine);
      final matchesSearch = _searchQuery.trim().isEmpty ||
          food.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          food.category.toLowerCase().contains(_searchQuery.trim().toLowerCase());
      return matchesCuisine && matchesSearch;
    }).toList();

    final bgColor = AppColors.ofBackground(context);
    final cardColor = AppColors.ofCardSurface(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Database',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Select foods to add to Today\'s Log',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '+ Create Custom Food',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const QuickAddFoodSheet(openInCustomMode: true),
              ).then((_) => setState(() {}));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Live Search Bar
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search foods by name (e.g. Parotta, Biryani, Chicken)...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                fillColor: AppColors.surfaceSubdued,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubdued, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Cuisine Filter Chips
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cuisines.map((cuisine) {
                  final isSelected = _selectedCuisine == cuisine;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cuisine),
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
                          _selectedCuisine = cuisine;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Food List with Multi-Select Checkboxes
          Expanded(
            child: filteredFoods.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.no_meals_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No food items found matching "${_searchQuery.trim()}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try changing your cuisine filter or search terms.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      final isChecked = _selectedFoods.contains(food);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _selectedFoods.remove(food);
                              } else {
                                _selectedFoods.add(food);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isChecked ? AppColors.accentSubtle : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked ? AppColors.primary : AppColors.borderSubdued,
                                width: isChecked ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkmark Control matching To-Do list style
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isChecked ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isChecked ? AppColors.primary : AppColors.borderSubdued,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: isChecked
                                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Food Dish Image Thumbnail
                                InkWell(
                                  onTap: () => showImagePreviewDialog(context, food.imageAsset, food.name),
                                  onDoubleTap: () => showImagePreviewDialog(context, food.imageAsset, food.name),
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppImageWidget(
                                    imagePath: food.imageAsset,
                                    width: 44,
                                    height: 44,
                                    borderRadius: BorderRadius.circular(8),
                                    fallbackIcon: Icons.restaurant,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Food Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            food.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isChecked ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Base: ${food.baseServing} • ${food.calories.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'P: ${food.proteinGrams}g • C: ${food.carbsGrams}g • F: ${food.fatGrams}g • Fib: ${food.fiberGrams}g',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Buttons (Edit & Delete for Custom Foods, plus Quick Add)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (food.isCustom) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                                        onPressed: () => _openEditCustomFoodModal(context, food),
                                        tooltip: 'Edit Custom Food',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                        onPressed: () => _confirmDeleteCustomFood(context, food),
                                        tooltip: 'Delete Custom Food',
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.tune, size: 18, color: AppColors.primary),
                                      onPressed: () => _openQuickAddModal(context, food),
                                      tooltip: 'Custom Quantity Quick Add',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Sticky Bottom Summary Dock for Bulk Add (Appears when >= 1 item selected)
          if (_selectedFoods.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                border: Border(top: BorderSide(color: AppColors.borderSubdued)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
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
                    final count = _selectedFoods.length;
                    ref.read(foodLogProvider.notifier).addLoggedFoods(
                          _selectedFoods.toList(),
                          mealSection: 'Lunch',
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $count ${count == 1 ? "food" : "foods"} to Today\'s Diet Journal!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Text(
                    '${_selectedFoods.length} ${_selectedFoods.length == 1 ? "item" : "items"} selected — Add to Log',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}
