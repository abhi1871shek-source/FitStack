import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image_widget.dart';
import '../../../core/widgets/image_preview_dialog.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';

class WorkoutQuickEditSheet extends ConsumerStatefulWidget {
  final WorkoutLogItem item;

  const WorkoutQuickEditSheet({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<WorkoutQuickEditSheet> createState() => _WorkoutQuickEditSheetState();
}

class _WorkoutQuickEditSheetState extends ConsumerState<WorkoutQuickEditSheet> {
  late List<ExerciseSet> _setsList;
  late List<TextEditingController> _repsControllers;
  late List<TextEditingController> _weightControllers;

  @override
  void initState() {
    super.initState();
    if (widget.item.setDetails.isNotEmpty) {
      _setsList = widget.item.setDetails.map((s) => s.copyWith()).toList();
    } else {
      _setsList = List.generate(
        widget.item.sets > 0 ? widget.item.sets : 3,
        (i) => ExerciseSet(
          setNumber: i + 1,
          reps: widget.item.reps,
          weightKg: widget.item.weightKg,
        ),
      );
    }

    _repsControllers = _setsList
        .map((s) => TextEditingController(text: s.reps.toString()))
        .toList();
    _weightControllers = _setsList
        .map((s) => TextEditingController(
            text: s.weightKg == s.weightKg.roundToDouble()
                ? s.weightKg.round().toString()
                : s.weightKg.toStringAsFixed(1)))
        .toList();
  }

  @override
  void dispose() {
    for (var c in _repsControllers) {
      c.dispose();
    }
    for (var c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllersToState() {
    for (int i = 0; i < _setsList.length && i < _repsControllers.length; i++) {
      final reps = int.tryParse(_repsControllers[i].text) ?? _setsList[i].reps;
      final weight = double.tryParse(_weightControllers[i].text) ?? _setsList[i].weightKg;
      _setsList[i] = _setsList[i].copyWith(
        reps: reps > 0 ? reps : 1,
        weightKg: weight >= 0 ? weight : 0.0,
      );
    }
  }

  void _addSet() {
    _syncControllersToState();
    setState(() {
      final lastSet = _setsList.isNotEmpty
          ? _setsList.last
          : ExerciseSet(setNumber: 1, reps: widget.item.reps, weightKg: widget.item.weightKg);
      final newSetNumber = _setsList.length + 1;
      final newSet = ExerciseSet(
        setNumber: newSetNumber,
        reps: lastSet.reps,
        weightKg: lastSet.weightKg,
      );
      _setsList.add(newSet);
      _repsControllers.add(TextEditingController(text: newSet.reps.toString()));
      _weightControllers.add(TextEditingController(
          text: newSet.weightKg == newSet.weightKg.roundToDouble()
              ? newSet.weightKg.round().toString()
              : newSet.weightKg.toStringAsFixed(1)));
    });
  }

  void _removeSet(int index) {
    if (_setsList.length <= 1) return;
    _syncControllersToState();
    setState(() {
      _repsControllers[index].dispose();
      _weightControllers[index].dispose();
      _setsList.removeAt(index);
      _repsControllers.removeAt(index);
      _weightControllers.removeAt(index);

      for (int i = 0; i < _setsList.length; i++) {
        _setsList[i] = _setsList[i].copyWith(setNumber: i + 1);
      }
    });
  }

  void _onSave() {
    final List<ExerciseSet> updatedDetails = [];
    for (int i = 0; i < _setsList.length; i++) {
      final reps = int.tryParse(_repsControllers[i].text) ?? _setsList[i].reps;
      final weight = double.tryParse(_weightControllers[i].text) ?? _setsList[i].weightKg;
      updatedDetails.add(ExerciseSet(
        setNumber: i + 1,
        reps: reps > 0 ? reps : 1,
        weightKg: weight >= 0 ? weight : 0.0,
      ));
    }

    ref.read(workoutProvider.notifier).editExercise(
          widget.item.id,
          setDetails: updatedDetails,
        );

    Navigator.pop(context);
  }

  Widget _buildSetCard(int index) {
    final setNum = index + 1;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ofBorderSubdued(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SET $setNum',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_setsList.length > 1)
                InkWell(
                  onTap: () => _removeSet(index),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.ofTextMuted(context),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStepperBox(
                  label: 'REPS',
                  controller: _repsControllers[index],
                  onDecrement: () {
                    final current = int.tryParse(_repsControllers[index].text) ?? 10;
                    if (current > 1) {
                      setState(() {
                        _repsControllers[index].text = (current - 1).toString();
                      });
                    }
                  },
                  onIncrement: () {
                    final current = int.tryParse(_repsControllers[index].text) ?? 10;
                    setState(() {
                      _repsControllers[index].text = (current + 1).toString();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStepperBox(
                  label: 'WEIGHT (kg)',
                  controller: _weightControllers[index],
                  onDecrement: () {
                    final current = double.tryParse(_weightControllers[index].text) ?? 0.0;
                    if (current >= 2.5) {
                      final newVal = current - 2.5;
                      setState(() {
                        _weightControllers[index].text = newVal == newVal.roundToDouble()
                            ? newVal.round().toString()
                            : newVal.toStringAsFixed(1);
                      });
                    } else if (current > 0) {
                      setState(() {
                        _weightControllers[index].text = '0';
                      });
                    }
                  },
                  onIncrement: () {
                    final current = double.tryParse(_weightControllers[index].text) ?? 0.0;
                    final newVal = current + 2.5;
                    setState(() {
                      _weightControllers[index].text = newVal == newVal.roundToDouble()
                          ? newVal.round().toString()
                          : newVal.toStringAsFixed(1);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperBox({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ofBorderSubdued(context)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.ofTextMuted(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ofTextPrimary(context),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkBackground : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ofBorderSubdued(context)),
                  ),
                  child: Icon(Icons.remove, size: 14, color: AppColors.ofTextSecondary(context)),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkBackground : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ofBorderSubdued(context)),
                  ),
                  child: Icon(Icons.add, size: 14, color: AppColors.ofTextSecondary(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (widget.item.effectiveImageUrl != null && widget.item.effectiveImageUrl!.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => showImagePreviewDialog(context, widget.item.effectiveImageUrl!, widget.item.name),
                  child: AppImageWidget(
                    imagePath: widget.item.effectiveImageUrl,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                    fallbackIcon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ofTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.item.muscleGroup} Exercise • ${_setsList.length} ${_setsList.length == 1 ? 'Set' : 'Sets'}',
                      style: TextStyle(fontSize: 12, color: AppColors.ofTextMuted(context)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppColors.ofTextMuted(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Sets List
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ...List.generate(_setsList.length, (i) => _buildSetCard(i)),
                  const SizedBox(height: 8),

                  // Add Set Button
                  InkWell(
                    onTap: _addSet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.ofAccentSubtle(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Add Set',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fixed Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _onSave,
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
