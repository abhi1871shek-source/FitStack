import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingReviewStep extends ConsumerWidget {
  final VoidCallback onBackToProfile;

  const OnboardingReviewStep({
    super.key,
    required this.onBackToProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    final String healthConcernsDisplay = state.healthConcerns.join(', ') +
        (state.otherHealthConcern.isNotEmpty ? ' (${state.otherHealthConcern})' : '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: onBackToProfile,
                        tooltip: 'Back to Profile',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'STEP 2 OF 2 • 100%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 4,
                      backgroundColor: AppColors.borderSubdued,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Summary Canvas
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline & Intro
                    const Text(
                      'Review Your Details',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Make sure everything looks right before we set up your personalized performance plan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Central High-Craft Summary Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubdued),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            label: 'WEIGHT',
                            value: '${state.weightKg?.toStringAsFixed(1) ?? '70'} kg',
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'HEIGHT',
                            value: '${state.heightCm?.toStringAsFixed(0) ?? '175'} cm',
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'AGE',
                            value: '${state.age ?? 25} yrs',
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'BIOLOGICAL SEX',
                            value: state.biologicalSex,
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'EXPERIENCE LEVEL',
                            value: state.experienceLevel ?? 'Beginner',
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'PRIMARY GOAL',
                            value: state.primaryGoal ?? 'Weight Loss',
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'HEALTH CONCERNS',
                            value: healthConcernsDisplay,
                            onEdit: onBackToProfile,
                          ),
                          _buildDivider(),
                          _buildSummaryRow(
                            label: 'BODY TYPE',
                            value: state.bodyType,
                            isLast: true,
                            onEdit: onBackToProfile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Micro-Callout Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubdued,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubdued),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_clock, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can adjust your profile details anytime in Settings & Profile as your body composition evolves.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trust Metadata Badge
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'KINOTIC PROTOCOL READY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Confirm Dock
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
                  onPressed: () {
                    // Complete onboarding in AuthNotifier
                    ref.read(authProvider.notifier).completeOnboarding(
                          weight: state.weightKg ?? 70.0,
                          height: state.heightCm ?? 175.0,
                          age: state.age ?? 25,
                          biologicalSex: state.biologicalSex,
                          goal: state.primaryGoal ?? 'Weight Loss',
                          level: state.experienceLevel ?? 'Beginner',
                          healthConcerns: state.healthConcerns,
                          otherHealthConcern: state.otherHealthConcern,
                          bodyType: state.bodyType,
                        );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Confirm & Continue',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required VoidCallback onEdit,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
            tooltip: 'Edit $label',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderSubdued);
  }
}
