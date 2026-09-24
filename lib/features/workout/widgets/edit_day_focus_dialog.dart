import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/weekly_plan_day.dart';

class EditDayFocusDialog extends StatefulWidget {
  final WeeklyPlanDay day;
  final Function(String newTitle, bool isRestDay) onSave;

  const EditDayFocusDialog({
    super.key,
    required this.day,
    required this.onSave,
  });

  @override
  State<EditDayFocusDialog> createState() => _EditDayFocusDialogState();
}

class _EditDayFocusDialogState extends State<EditDayFocusDialog> {
  late bool _isRestDay;
  late TextEditingController _titleController;
  String _selectedPreset = '';

  static const List<String> _presets = [
    'Push Day (Chest & Triceps)',
    'Pull Day (Back & Biceps)',
    'Legs & Core',
    'Full Body Workout',
    'Upper Body Focus',
    'Lower Body & Core',
    'Shoulders & Arms',
    'Cardio & Core',
  ];

  @override
  void initState() {
    super.initState();
    _isRestDay = widget.day.isRestDay;
    _titleController = TextEditingController(text: widget.day.focusTitle);
    if (_presets.contains(widget.day.focusTitle)) {
      _selectedPreset = widget.day.focusTitle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubdued),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit ${widget.day.dayName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Target Day Focus & Split',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rest Day Switch Toggle Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRestDay
                      ? AppColors.surfaceSubdued
                      : AppColors.accentSubtle.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRestDay ? AppColors.borderSubdued : AppColors.primary,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRestDay ? Icons.bedtime : Icons.fitness_center,
                          color: _isRestDay ? AppColors.textMuted : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRestDay ? 'Rest & Recovery Day' : 'Active Training Day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isRestDay ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _isRestDay ? 'No workouts scheduled' : 'Assigned muscle group',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isRestDay,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isRestDay = val;
                          if (val) {
                            _titleController.text = 'Rest & Recovery';
                            _selectedPreset = '';
                          } else if (_titleController.text == 'Rest & Recovery') {
                            _titleController.text = _presets.first;
                            _selectedPreset = _presets.first;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (!_isRestDay) ...[
                const SizedBox(height: 16),
                const Text(
                  'Select Preset Focus',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Preset Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    final isSelected = _selectedPreset == preset;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPreset = preset;
                          _titleController.text = preset;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentSubtle : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.borderSubdued,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Or Custom Focus Name',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  onChanged: (val) {
                    if (_selectedPreset != val) {
                      setState(() {
                        _selectedPreset = '';
                      });
                    }
                  },
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'e.g. Core & Calves Focus',
                    filled: true,
                    fillColor: AppColors.surfaceSubdued,
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
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final finalTitle = title.isNotEmpty
                          ? title
                          : (_isRestDay ? 'Rest & Recovery' : 'Full Body Workout');
                      widget.onSave(finalTitle, _isRestDay);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Save Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
