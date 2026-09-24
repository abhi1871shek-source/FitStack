import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themePrefKey = 'app_theme_mode';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'system') {
        state = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('[ThemeNotifier] Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme([bool? isDark]) async {
    final nextMode = isDark != null
        ? (isDark ? ThemeMode.dark : ThemeMode.light)
        : (state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

    state = nextMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, nextMode.name);
    } catch (e) {
      debugPrint('[ThemeNotifier] Error saving theme preference: $e');
    }
  }
}
