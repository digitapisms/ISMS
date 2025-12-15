import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_config.dart';

/// Provider for current theme type
final themeTypeProvider = StateNotifierProvider<ThemeTypeNotifier, AppThemeType>((ref) {
  return ThemeTypeNotifier();
});

/// Provider for current theme mode (light/dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeTypeNotifier extends StateNotifier<AppThemeType> {
  ThemeTypeNotifier() : super(AppThemeType.defaultTheme) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('app_theme') ?? 'defaultTheme';
    state = AppThemeType.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => AppThemeType.defaultTheme,
    );
  }

  Future<void> setTheme(AppThemeType theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.name);
  }
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString('theme_mode') ?? 'system';
    state = AppThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

