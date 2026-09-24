import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_signup_screen.dart';
import 'features/onboarding/screens/onboarding_flow_screen.dart';
import 'navigation/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  // Initialize Supabase client
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('[Supabase] Initialized successfully. Ready to connect.');
  } catch (e, st) {
    debugPrint('[Supabase] Initialization error: $e\n$st');
  }

  runApp(const ProviderScope(child: FitStackApp()));
}

class FitStackApp extends ConsumerWidget {
  const FitStackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    Widget homeScreen;
    if (user == null) {
      homeScreen = const LoginSignupScreen();
    } else if (!user.isProfileComplete) {
      homeScreen = const OnboardingFlowScreen();
    } else {
      homeScreen = const MainShell();
    }

    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FitStack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: homeScreen,
    );
  }
}
