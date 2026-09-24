import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';
import 'onboarding_profile_step.dart';
import 'onboarding_review_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialStep = ref.read(onboardingProvider).currentStep;
    _pageController = PageController(initialPage: initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to currentStep changes from provider
    ref.listen<int>(
      onboardingProvider.select((s) => s.currentStep),
      (previous, next) {
        if (_pageController.hasClients && _pageController.page?.round() != next) {
          _navigateToPage(next);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disables accidental swiping during form typing
            children: [
              OnboardingProfileStep(
                onContinue: () {
                  ref.read(onboardingProvider.notifier).goToStep(1);
                },
              ),
              OnboardingReviewStep(
                onBackToProfile: () {
                  ref.read(onboardingProvider.notifier).goToStep(0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
