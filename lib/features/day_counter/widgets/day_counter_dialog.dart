import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/day_counter.dart';
import '../providers/day_counter_provider.dart';

class DayCounterDialog extends ConsumerStatefulWidget {
  final DayCounter? counterToEdit;

  const DayCounterDialog({super.key, this.counterToEdit});

  @override
  ConsumerState<DayCounterDialog> createState() => _DayCounterDialogState();
}

class _DayCounterDialogState extends ConsumerState<DayCounterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetDaysController;
  late DayCounterMode _selectedMode;
  late DateTime _selectedStartDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.counterToEdit != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.counterToEdit;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _targetDaysController = TextEditingController(
      text: existing?.targetDays != null ? existing!.targetDays.toString() : '30',
    );
    _selectedMode = existing?.mode ?? DayCounterMode.countup;
    if (existing != null) {
      _selectedStartDate = existing.startDate;
    } else {
      final now = DateTime.now();
      _selectedStartDate = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedStartDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim();
    int? targetDays;
    if (_selectedMode == DayCounterMode.countdown) {
      targetDays = int.tryParse(_targetDaysController.text.trim()) ?? 30;
      if (targetDays <= 0) targetDays = 1;
    }

    final notifier = ref.read(dayCountersProvider.notifier);
    bool success = false;

    if (_isEditing) {
      success = await notifier.updateCounter(
        id: widget.counterToEdit!.id,
        title: title,
        mode: _selectedMode,
        startDate: _selectedStartDate,
        targetDays: targetDays,
      );
    } else {
      final created = await notifier.addCounter(
        title: title,
        mode: _selectedMode,
        startDate: _selectedStartDate,
        targetDays: targetDays,
      );
      success = created != null;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Counter updated!' : 'Counter created!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save counter. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.ofCardSurface(context);
    final txtPrimary = AppColors.ofTextPrimary(context);
    final txtMuted = AppColors.ofTextMuted(context);
    final border = AppColors.ofBorderSubdued(context);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isEditing ? 'Edit Day Counter' : 'New Day Counter',
                        style: AppTypography.h2.copyWith(color: txtPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: txtMuted,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector
                  Text(
                    'COUNTER MODE',
                    style: AppTypography.labelUpper.copyWith(color: txtMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = DayCounterMode.countup),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedMode == DayCounterMode.countup
                                  ? AppColors.primary.withOpacity(isDark ? 0.25 : 0.12)
                                  : AppColors.ofSurfaceSubdued(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMode == DayCounterMode.countup
                                    ? AppColors.primary
                                    : border,
                                width: _selectedMode == DayCounterMode.countup ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 22,
                                  color: _selectedMode == DayCounterMode.countup
                                      ? AppColors.primary
                                      : txtMuted,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Count Up',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedMode == DayCounterMode.countup
                                        ? AppColors.primary
                                        : txtPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Starts at Day 1',
                                  style: TextStyle(fontSize: 10, color: txtMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMode = DayCounterMode.countdown),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedMode == DayCounterMode.countdown
                                  ? Colors.orange.withOpacity(isDark ? 0.25 : 0.12)
                                  : AppColors.ofSurfaceSubdued(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedMode == DayCounterMode.countdown
                                    ? Colors.orange
                                    : border,
                                width: _selectedMode == DayCounterMode.countdown ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.hourglass_bottom,
                                  size: 22,
                                  color: _selectedMode == DayCounterMode.countdown
                                      ? Colors.orange
                                      : txtMuted,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Count Down',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedMode == DayCounterMode.countdown
                                        ? Colors.orange
                                        : txtPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Shows days left',
                                  style: TextStyle(fontSize: 10, color: txtMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  Text(
                    'TITLE',
                    style: AppTypography.labelUpper.copyWith(color: txtMuted),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: txtPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _selectedMode == DayCounterMode.countup
                          ? 'e.g. 75 Hard, Sugar Free Streak'
                          : 'e.g. Summer Goal, Marathon Prep',
                      hintStyle: TextStyle(color: txtMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.ofSurfaceSubdued(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Target days (countdown only)
                  if (_selectedMode == DayCounterMode.countdown) ...[
                    Text(
                      'TARGET DAYS (N)',
                      style: AppTypography.labelUpper.copyWith(color: txtMuted),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _targetDaysController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: txtPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 30, 60, 100',
                        hintStyle: TextStyle(color: txtMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.ofSurfaceSubdued(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        suffixText: 'days',
                        suffixStyle: TextStyle(color: txtMuted, fontSize: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter target days';
                        }
                        final numVal = int.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Start Date Picker
                  Text(
                    'START DATE (LOCAL IST)',
                    style: AppTypography.labelUpper.copyWith(color: txtMuted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.ofSurfaceSubdued(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedStartDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: txtPrimary,
                              ),
                            ),
                          ),
                          const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: txtMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isEditing ? 'Save Changes' : 'Create Counter',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
