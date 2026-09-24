import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
  late int _sets;
  late int _reps;
  late double _weightKg;

  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _sets = widget.item.sets;
    _reps = widget.item.reps;
    _weightKg = widget.item.weightKg;

    _setsController = TextEditingController(text: _sets.toString());
    _repsController = TextEditingController(text: _reps.toString());
    _weightController = TextEditingController(text: _weightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.item.muscleGroup} Exercise',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Steppers Grid for Sets, Reps, Weight
          Row(
            children: [
              Expanded(
                child: _buildStepperBox(
                  label: 'SETS',
                  controller: _setsController,
                  onDecrement: () {
                    if (_sets > 1) {
                      setState(() {
                        _sets--;
                        _setsController.text = _sets.toString();
                      });
                    }
                  },
                  onIncrement: () {
                    setState(() {
                      _sets++;
                      _setsController.text = _sets.toString();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStepperBox(
                  label: 'REPS',
                  controller: _repsController,
                  onDecrement: () {
                    if (_reps > 1) {
                      setState(() {
                        _reps--;
                        _repsController.text = _reps.toString();
                      });
                    }
                  },
                  onIncrement: () {
                    setState(() {
                      _reps++;
                      _repsController.text = _reps.toString();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStepperBox(
                  label: 'WEIGHT (kg)',
                  controller: _weightController,
                  onDecrement: () {
                    if (_weightKg >= 2.5) {
                      setState(() {
                        _weightKg -= 2.5;
                        _weightController.text = _weightKg.toStringAsFixed(1);
                      });
                    }
                  },
                  onIncrement: () {
                    setState(() {
                      _weightKg += 2.5;
                      _weightController.text = _weightKg.toStringAsFixed(1);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final parsedSets = int.tryParse(_setsController.text) ?? _sets;
                final parsedReps = int.tryParse(_repsController.text) ?? _reps;
                final parsedWeight = double.tryParse(_weightController.text) ?? _weightKg;

                ref.read(workoutProvider.notifier).editExercise(
                      widget.item.id,
                      sets: parsedSets,
                      reps: parsedReps,
                      weightKg: parsedWeight,
                    );

                Navigator.pop(context);
              },
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

  Widget _buildStepperBox({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubdued),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubdued),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: AppColors.textSecondary),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubdued),
                  ),
                  child: const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
