import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

class NavDestinationData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestinationData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestinationData> destinations;
  final Widget body;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.ofBackground(context);
    final cardColor = AppColors.ofCardSurface(context);
    final textPrimaryColor = AppColors.ofTextPrimary(context);
    final textMutedColor = AppColors.ofTextMuted(context);
    final borderColor = AppColors.ofBorderSubdued(context);
    final accentSubtleColor = AppColors.ofAccentSubtle(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: cardColor,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedIconTheme: IconThemeData(color: textMutedColor),
                  unselectedLabelTextStyle: TextStyle(color: textMutedColor),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: AppColors.primary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'FitStack',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: IconButton(
                          icon: Icon(Icons.logout, color: textMutedColor, size: 20),
                          tooltip: 'Log Out',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: cardColor,
                                title: Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to log out of FitStack?',
                                  style: TextStyle(color: textPrimaryColor),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: textMutedColor),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      Supabase.instance.client.auth.signOut();
                                    },
                                    child: const Text('Log Out'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                VerticalDivider(thickness: 1, width: 1, color: borderColor),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            backgroundColor: cardColor,
            indicatorColor: accentSubtleColor,
            destinations: destinations
                .map(
                  (d) => NavigationDestination(
                    icon: Icon(d.icon, color: textMutedColor),
                    selectedIcon: Icon(d.selectedIcon, color: AppColors.primary),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
