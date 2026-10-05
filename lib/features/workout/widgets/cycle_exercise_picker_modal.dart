import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image_widget.dart';
import '../data/exercise_library.dart';
import '../models/exercise.dart';
import '../models/workout_cycle_exercise.dart';
import '../providers/workout_weekly_plan_provider.dart';

class CycleExercisePickerModal extends ConsumerStatefulWidget {
  final int cycleNumber;
  final int dayIndex;
  final String dayName;
  final List<WorkoutCycleExercise> currentExercises;

  const CycleExercisePickerModal({
    super.key,
    required this.cycleNumber,
    required this.dayIndex,
    required this.dayName,
    required this.currentExercises,
  });

  @override
  ConsumerState<CycleExercisePickerModal> createState() => _CycleExercisePickerModalState();
}

class _CycleExercisePickerModalState extends ConsumerState<CycleExercisePickerModal> {
  String _selectedBodyPart = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Exercise> _selectedExercisesMap = {};

  final List<String> _bodyParts = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  @override
  void initState() {
    super.initState();
    for (final ex in widget.currentExercises) {
      final masterEx = ExerciseLibrary.masterExercises.firstWhere(
        (e) => e.id == ex.exerciseId,
        orElse: () => Exercise(
          id: ex.exerciseId,
          name: ex.exerciseName,
          muscleGroup: ex.muscleGroup,
          defaultSets: ex.targetSets,
          defaultReps: ex.targetReps,
          defaultWeightKg: ex.targetWeightKg,
        ),
      );
      _selectedExercisesMap[ex.exerciseId] = masterEx;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = ExerciseLibrary.masterExercises.where((ex) {
      final matchesFilter = _selectedBodyPart == 'All' ||
          ex.muscleGroup.toLowerCase() == _selectedBodyPart.toLowerCase();
      final matchesSearch = _searchQuery.trim().isEmpty ||
          ex.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Modal Handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.borderSubdued)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubdued,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle ${widget.cycleNumber} • ${widget.dayName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select exercises for this template day (${_selectedExercisesMap.length} selected)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search exercises by name...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                fillColor: AppColors.surfaceSubdued,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubdued),
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _bodyParts.map((part) {
                  final isSelected = _selectedBodyPart == part;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(part, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceSubdued,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _selectedBodyPart = part),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSubdued),

          // Exercises List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredExercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ex = filteredExercises[index];
                final isSelected = _selectedExercisesMap.containsKey(ex.id);
                final imgPath = ex.imageUrl != null && ex.imageUrl!.isNotEmpty
                    ? ex.imageUrl!
                    : 'assets/images/exercises/${ex.id}.jpg';

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedExercisesMap.remove(ex.id);
                      } else {
                        _selectedExercisesMap[ex.id] = ex;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentSubtle : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderSubdued,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        AppImageWidget(
                          imagePath: imgPath,
                          width: 42,
                          height: 42,
                          borderRadius: BorderRadius.circular(8),
                          fallbackIcon: Icons.fitness_center,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ex.muscleGroup} • ${ex.defaultSets} sets × ${ex.defaultReps} reps',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedExercisesMap[ex.id] = ex;
                              } else {
                                _selectedExercisesMap.remove(ex.id);
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

          // Bottom Action Dock
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
                ),
                onPressed: () async {
                  final selectedList = _selectedExercisesMap.values.toList();
                  await ref.read(workoutWeeklyPlanProvider.notifier).saveExercisesForCycleDay(
                        cycleNumber: widget.cycleNumber,
                        dayIndex: widget.dayIndex,
                        selectedExercises: selectedList,
                      );
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  'Save (${_selectedExercisesMap.length}) Exercises to Cycle ${widget.cycleNumber}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
