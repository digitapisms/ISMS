import 'package:flutter/material.dart';

/// Available app themes
enum AppThemeType {
  defaultTheme('Default', 'Modern indigo and purple'),
  ocean('Ocean', 'Calming blue and teal'),
  forest('Forest', 'Natural green and emerald'),
  highContrast('High Contrast', 'Enhanced visibility for accessibility');

  final String name;
  final String description;
  const AppThemeType(this.name, this.description);
}

/// Theme mode (light/dark/system)
enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  system('System');

  final String name;
  const AppThemeMode(this.name);

  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.system;
    }
  }
}

/// Theme color configurations
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final String name;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.name,
  });

  static const defaultTheme = ThemeColors(
    primary: Color(0xFF6366F1), // Indigo
    secondary: Color(0xFF8B5CF6), // Purple
    tertiary: Color(0xFFEC4899), // Pink
    name: 'Default',
  );

  static const ocean = ThemeColors(
    primary: Color(0xFF0EA5E9), // Sky Blue
    secondary: Color(0xFF06B6D4), // Cyan
    tertiary: Color(0xFF14B8A6), // Teal
    name: 'Ocean',
  );

  static const forest = ThemeColors(
    primary: Color(0xFF10B981), // Emerald
    secondary: Color(0xFF059669), // Green
    tertiary: Color(0xFF34D399), // Light Green
    name: 'Forest',
  );

  static const highContrast = ThemeColors(
    primary: Color(0xFF000000), // Black
    secondary: Color(0xFFFFFFFF), // White
    tertiary: Color(0xFFFF0000), // Red
    name: 'High Contrast',
  );

  static ThemeColors fromType(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultTheme:
        return defaultTheme;
      case AppThemeType.ocean:
        return ocean;
      case AppThemeType.forest:
        return forest;
      case AppThemeType.highContrast:
        return highContrast;
    }
  }
}
