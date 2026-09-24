import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';

class WorkoutAddLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutAddLibraryScreen({super.key});

  @override
  ConsumerState<WorkoutAddLibraryScreen> createState() => _WorkoutAddLibraryScreenState();
}

class _WorkoutAddLibraryScreenState extends ConsumerState<WorkoutAddLibraryScreen> {
  String _selectedBodyPart = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<Exercise> _selectedExercises = {};

  final List<String> _bodyParts = [
    'All',
    'Home',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomExerciseModal(BuildContext context) {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '0.0');

    String selectedMuscleGroup = _selectedBodyPart != 'All' && _selectedBodyPart != 'Home'
        ? _selectedBodyPart
        : 'Chest';
    bool isHomeExercise = false;

    final muscleGroups = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Row(
                      children: [
                        Icon(Icons.fitness_center, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Create Custom Exercise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name',
                        hintText: 'e.g. Weighted Pull-Up',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedMuscleGroup,
                      decoration: const InputDecoration(labelText: 'Target Muscle Group'),
                      items: muscleGroups
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedMuscleGroup = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: setsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Default Sets'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: repsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Default Reps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              suffixText: 'kg',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('Home Friendly Exercise', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Can be performed without heavy gym machinery',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      value: isHomeExercise,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => isHomeExercise = val ?? false);
                      },
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
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          final sets = int.tryParse(setsController.text.trim()) ?? 3;
                          final reps = int.tryParse(repsController.text.trim()) ?? 10;
                          final weight = double.tryParse(weightController.text.trim()) ?? 0.0;
                          final customId = 'ex_custom_${DateTime.now().millisecondsSinceEpoch}';

                          final customEx = Exercise(
                            id: customId,
                            name: name,
                            muscleGroup: selectedMuscleGroup,
                            defaultSets: sets,
                            defaultReps: reps,
                            defaultWeightKg: weight,
                            isHome: isHomeExercise,
                          );

                          try {
                            // 1. Save to Supabase exercises table
                            final client = Supabase.instance.client;
                            final userId = client.auth.currentUser?.id;
                            if (userId != null) {
                              final map = customEx.toMap();
                              map['user_id'] = userId;
                              await client.from('exercises').upsert(map, onConflict: 'id');
                            }

                            // 2. Add to exercise library in memory
                            if (!ExerciseLibrary.masterExercises.any((e) => e.id == customId)) {
                              ExerciseLibrary.masterExercises.insert(0, customEx);
                            }

                            // 3. Log to today's workout
                            ref.read(workoutProvider.notifier).addExercises([customEx]);

                            if (mounted) {
                              Navigator.pop(dialogCtx);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Custom exercise "$name" saved to DB & added to Workout!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('[WorkoutAddLibraryScreen] Error saving custom exercise: $e');
                            ref.read(workoutProvider.notifier).addExercises([customEx]);
                            if (mounted) {
                              Navigator.pop(dialogCtx);
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Save Custom Exercise & Add to Workout',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userHealthConcerns = user?.healthConcerns ?? [];
    final otherConcern = user?.otherHealthConcern ?? '';

    final activeHealthTags = <String>[];
    for (final concern in userHealthConcerns) {
      if (concern == 'Back Pain') activeHealthTags.add('back_pain');
      if (concern == 'Knee Pain') activeHealthTags.add('knee_pain');
      if (concern == 'Joint Issues') activeHealthTags.add('joint_issues');
    }
    if (otherConcern.toLowerCase().contains('back')) activeHealthTags.add('back_pain');
    if (otherConcern.toLowerCase().contains('knee')) activeHealthTags.add('knee_pain');

    final filteredExercises = ExerciseLibrary.masterExercises.where((ex) {
      final matchesFilter = _selectedBodyPart == 'All'
          ? true
          : (_selectedBodyPart == 'Home'
              ? ex.isHome
              : ex.muscleGroup.toLowerCase() == _selectedBodyPart.toLowerCase());
      final matchesSearch = _searchQuery.trim().isEmpty ||
          ex.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Select exercises to add to Today\'s Workout',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '+ Create Custom Exercise',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showAddCustomExerciseModal(context),
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
                hintText: 'Search exercises by name...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubdued),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Body Part Filter Chips
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _bodyParts.map((part) {
                  final isSelected = _selectedBodyPart == part;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(part),
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
                          _selectedBodyPart = part;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSubdued),

          // Exercise List Area
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No exercises match your search!',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddCustomExerciseModal(context),
                          icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                          label: const Text('Create Custom Exercise',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ex = filteredExercises[index];
                      final isSelected = _selectedExercises.contains(ex);

                      final isContraindicated = activeHealthTags.any(
                        (tag) => ex.avoidIf.contains(tag),
                      );

                      final String imgPath = ex.imageUrl != null && ex.imageUrl!.isNotEmpty
                          ? ex.imageUrl!
                          : 'assets/images/exercises/${ex.id}.jpg';

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedExercises.remove(ex);
                            } else {
                              _selectedExercises.add(ex);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentSubtle : AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderSubdued,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => showImagePreviewDialog(context, imgPath, ex.name),
                                onDoubleTap: () => showImagePreviewDialog(context, imgPath, ex.name),
                                borderRadius: BorderRadius.circular(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    imgPath,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.surfaceSubdued,
                                      child: const Icon(Icons.fitness_center,
                                          size: 20, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ex.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isContraindicated)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFF59E0B)),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded,
                                                    size: 11, color: Color(0xFFD97706)),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Caution',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceSubdued,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            ex.muscleGroup,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${ex.defaultSets} sets × ${ex.defaultReps} reps • ${ex.defaultWeightKg.round()} kg',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedExercises.add(ex);
                                    } else {
                                      _selectedExercises.remove(ex);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Sticky Bottom Action Dock
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              border: Border(top: BorderSide(color: AppColors.borderSubdued)),
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
                onPressed: _selectedExercises.isEmpty
                    ? null
                    : () {
                        ref.read(workoutProvider.notifier).addExercises(_selectedExercises.toList());
                        Navigator.pop(context);
                      },
                child: Text(
                  _selectedExercises.isEmpty
                      ? 'Select Exercises'
                      : 'Add Selected (${_selectedExercises.length})',
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
