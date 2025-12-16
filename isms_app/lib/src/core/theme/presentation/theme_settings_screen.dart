import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme_config.dart';
import '../theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeTypeProvider);
    final currentMode = ref.watch(themeModeProvider);
    final themeTypeNotifier = ref.read(themeTypeProvider.notifier);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose light or dark mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<AppThemeMode>(
                    segments: AppThemeMode.values.map((mode) {
                      return ButtonSegment<AppThemeMode>(
                        value: mode,
                        label: Text(mode.name),
                        icon: Icon(_getModeIcon(mode)),
                      );
                    }).toList(),
                    selected: {currentMode},
                    onSelectionChanged: (Set<AppThemeMode> selection) {
                      themeModeNotifier.setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Theme Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Theme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your preferred color scheme',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...AppThemeType.values.map((themeType) {
                    final themeColors = ThemeColors.fromType(themeType);
                    final isSelected = currentTheme == themeType;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          themeTypeNotifier.setTheme(themeType);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? themeColors.primary
                                  : colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? themeColors.primary.withOpacity(0.1)
                                : colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              // Color preview
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      themeColors.primary,
                                      themeColors.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Theme info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      themeColors.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? themeColors.primary
                                                : null,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getThemeDescription(themeType),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Selection indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: themeColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeDescription(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultTheme:
        return 'Modern indigo and purple colors';
      case AppThemeType.ocean:
        return 'Calming blue and teal tones';
      case AppThemeType.forest:
        return 'Natural green and emerald shades';
      case AppThemeType.highContrast:
        return 'Enhanced visibility for accessibility';
    }
  }
}
