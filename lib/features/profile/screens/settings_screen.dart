import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../diet/providers/diet_preference_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _otherHealthController;
  late TextEditingController _calorieTargetController;

  late String _biologicalSex;
  late String _experienceLevel;
  late String _primaryGoal;
  late String _bodyType;
  late List<String> _selectedHealthConcerns;

  bool _isSaving = false;

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _levelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'Maintain Weight',
    'General Fitness',
    'Athletic Performance'
  ];
  final List<String> _bodyTypeOptions = [
    'Average',
    'Ectomorph',
    'Mesomorph',
    'Endomorph'
  ];
  final List<String> _healthConcernOptions = [
    'None',
    'Joint Pain',
    'High Blood Pressure',
    'Diabetes',
    'Asthma',
    'Back Issues'
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    final dietPref = ref.read(dietPreferenceProvider);
    final currentCalorieTarget = dietPref.calorieTarget ?? ref.read(dietPreferenceProvider.notifier).calculatedCalories;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _ageController = TextEditingController(
        text: user?.age != null ? user!.age.toString() : '25');
    _weightController = TextEditingController(
        text: user?.weightKg != null ? user!.weightKg.toString() : '70');
    _heightController = TextEditingController(
        text: user?.heightCm != null ? user!.heightCm.toString() : '175');
    _otherHealthController =
        TextEditingController(text: user?.otherHealthConcern ?? '');
    _calorieTargetController =
        TextEditingController(text: currentCalorieTarget.toString());

    _biologicalSex = user?.biologicalSex ?? 'Male';
    if (!_sexOptions.contains(_biologicalSex)) {
      _biologicalSex = 'Male';
    }

    _experienceLevel = user?.experienceLevel ?? 'Intermediate';
    if (!_levelOptions.contains(_experienceLevel)) {
      _experienceLevel = 'Intermediate';
    }

    _primaryGoal = user?.primaryGoal ?? 'Muscle Gain';
    if (!_goalOptions.contains(_primaryGoal)) {
      _primaryGoal = 'Muscle Gain';
    }

    _bodyType = user?.bodyType ?? 'Average';
    if (!_bodyTypeOptions.contains(_bodyType)) {
      _bodyType = 'Average';
    }

    _selectedHealthConcerns = List<String>.from(user?.healthConcerns ?? []);
    if (_selectedHealthConcerns.isEmpty) {
      _selectedHealthConcerns.add('None');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _otherHealthController.dispose();
    _calorieTargetController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      displayName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 25,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 70.0,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 175.0,
      biologicalSex: _biologicalSex,
      experienceLevel: _experienceLevel,
      primaryGoal: _primaryGoal,
      bodyType: _bodyType,
      healthConcerns: _selectedHealthConcerns,
      otherHealthConcern: _otherHealthController.text.trim(),
      isProfileComplete: true,
    );

    await ref.read(authProvider.notifier).updateProfile(updatedUser);

    final calorieVal = int.tryParse(_calorieTargetController.text.trim());
    if (calorieVal != null && calorieVal > 0) {
      ref.read(dietPreferenceProvider.notifier).setCalorieTarget(calorieVal);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profile & Calorie settings saved to Supabase!'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Name & Email (Readonly email)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name / Display Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 14),

                // Metrics Row (Age, Weight, Height)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          suffixText: 'yrs',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (val) =>
                            val == null || int.tryParse(val) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (val) =>
                            val == null || double.tryParse(val) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (val) =>
                            val == null || double.tryParse(val) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Nutrition & Daily Target',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _calorieTargetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Target',
                    suffixText: 'kcal',
                    prefixIcon: Icon(Icons.local_fire_department_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    helperText: 'Manually override your daily calorie goal',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a calorie target';
                    }
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed < 500 || parsed > 10000) {
                      return 'Enter valid calories (500-10,000)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Fitness Profile & Goals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Biological Sex
                DropdownButtonFormField<String>(
                  value: _biologicalSex,
                  decoration: const InputDecoration(
                    labelText: 'Biological Sex',
                    prefixIcon: Icon(Icons.wc, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  items: _sexOptions
                      .map((sex) => DropdownMenuItem(
                            value: sex,
                            child: Text(sex),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _biologicalSex = val);
                  },
                ),
                const SizedBox(height: 14),

                // Primary Goal
                DropdownButtonFormField<String>(
                  value: _primaryGoal,
                  decoration: const InputDecoration(
                    labelText: 'Primary Fitness Goal',
                    prefixIcon: Icon(Icons.flag_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  items: _goalOptions
                      .map((goal) => DropdownMenuItem(
                            value: goal,
                            child: Text(goal),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _primaryGoal = val);
                  },
                ),
                const SizedBox(height: 14),

                // Experience Level & Body Type Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _experienceLevel,
                        decoration: const InputDecoration(
                          labelText: 'Experience Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items: _levelOptions
                            .map((lvl) => DropdownMenuItem(
                                  value: lvl,
                                  child: Text(lvl,
                                      style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _experienceLevel = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _bodyType,
                        decoration: const InputDecoration(
                          labelText: 'Body Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        items: _bodyTypeOptions
                            .map((bt) => DropdownMenuItem(
                                  value: bt,
                                  child: Text(bt,
                                      style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _bodyType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Health Concerns Multi-Select Chips
                const Text(
                  'Health & Physical Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _healthConcernOptions.map((concern) {
                    final isSelected =
                        _selectedHealthConcerns.contains(concern);
                    return ChoiceChip(
                      label: Text(concern),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (concern == 'None') {
                            _selectedHealthConcerns = ['None'];
                          } else {
                            _selectedHealthConcerns.remove('None');
                            if (selected) {
                              _selectedHealthConcerns.add(concern);
                            } else {
                              _selectedHealthConcerns.remove(concern);
                            }
                            if (_selectedHealthConcerns.isEmpty) {
                              _selectedHealthConcerns.add('None');
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Submit Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSaving ? null : _saveSettings,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Profile Changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
